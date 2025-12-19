using Azure;
using ImputationApi.Extensions;
using ImputationApi.Models;
using System.ComponentModel;

namespace ImputationApi.Services
{
    public sealed class ImputationService(ILogger<ImputationService> logger, IConfiguration configuration, IWebHostEnvironment environment, IBlobStorageService blobStorageService) : IImputationService
    {
        private const string DefaultDistro = "Ubuntu";
        private const string OutputDirectoryName = "output";

        private readonly ILogger<ImputationService> _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        private readonly IConfiguration _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        private readonly IWebHostEnvironment _environment = environment ?? throw new ArgumentNullException(nameof(environment));
        private readonly IBlobStorageService _blobStorageService = blobStorageService ?? throw new ArgumentNullException(nameof(blobStorageService));

        public string ResolveRepositoryWindowsPath()
        {
            string contentRootPath = _environment.ContentRootPath;
            DirectoryInfo? clientDirectory = Directory.GetParent(contentRootPath) ?? throw new InvalidOperationException("Unable to resolve client directory from content root path: " + contentRootPath);
            DirectoryInfo? repositoryRootDirectory = clientDirectory.Parent;

            return repositoryRootDirectory == null
                ? throw new InvalidOperationException("Unable to resolve repository root directory from client directory: " + clientDirectory.FullName)
                : repositoryRootDirectory.FullName;
        }

        public async Task RunAsync(ImputationJob job, CancellationToken cancellationToken)
        {
            ArgumentNullException.ThrowIfNull(job);

            string? downloadDirectory = null;
            string? referencePanelDirectory = null;

            try
            {
                job.Status = ImputationStatus.Running;

                string repositoryPath = job.EnsureRepositoryPath();

                if (job.DownloadUrls is { Count: > 0 })
                {
                    downloadDirectory = await DownloadInputFilesAsync(job, repositoryPath, cancellationToken);
                    if (downloadDirectory == null)
                    {
                        return;
                    }
                }

                if (job.ReferencePanelDownloadUrl != null)
                {
                    referencePanelDirectory = await DownloadReferencePanelAsync(job, repositoryPath, cancellationToken);
                    if (referencePanelDirectory == null)
                    {
                        return;
                    }
                }

                string nextflowCommand = BuildNextflowCommand(job);
                int exitCode = await RunNextflowAsync(job, nextflowCommand, cancellationToken);
                job.ExitCode = exitCode;

                await HandleCompletionAsync(job, exitCode, cancellationToken);
            }
            catch (Exception ex) when (
                ex is HttpRequestException
                or RequestFailedException
                or InvalidOperationException
                or IOException
                or UnauthorizedAccessException
                or Win32Exception
                or NotSupportedException)
            {
                FailJob(job, ex);
            }
            finally
            {
                job.FinishedAt = DateTimeOffset.UtcNow;
                CleanupDirectory(downloadDirectory, job.Id, "downloaded files directory");
                CleanupDirectory(referencePanelDirectory, job.Id, "reference panel directory");
            }
        }

        private async Task<string?> DownloadInputFilesAsync(ImputationJob job, string repositoryPath, CancellationToken cancellationToken)
        {
            string shortId = job.Id.ToString("N")[..8];
            string downloadDirectory = Path.Combine(repositoryPath, "downloaded", shortId);
            _ = Directory.CreateDirectory(downloadDirectory);

            using HttpClient httpClient = new();

            foreach (Uri? uri in job.DownloadUrls!)
            {
                cancellationToken.ThrowIfCancellationRequested();

                if (uri == null)
                {
                    continue;
                }

                try
                {
                    string fileName = Path.GetFileName(uri.LocalPath);

                    if (string.IsNullOrWhiteSpace(fileName))
                    {
                        fileName = Guid.NewGuid().ToString("N") + ".vcf.gz";
                    }

                    string targetPath = Path.Combine(downloadDirectory, fileName);

                    using HttpResponseMessage response = await httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
                    _ = response.EnsureSuccessStatusCode();

                    await using FileStream fileStream = File.Create(targetPath);
                    await response.Content.CopyToAsync(fileStream, cancellationToken);
                }
                catch (HttpRequestException ex)
                {
                    _logger.LogError(ex, "Error downloading file from {Url} for job {JobId}", uri.ToString(), job.Id);
                    job.Status = ImputationStatus.Failed;
                    job.ErrorMessage = "Failed to download " + uri.ToString() + ": " + ex.Message;

                    return null;
                }
            }

            job.InputFilesPath = downloadDirectory;

            return downloadDirectory;
        }

        private async Task<string?> DownloadReferencePanelAsync(ImputationJob job, string repositoryPath, CancellationToken cancellationToken)
        {
            Uri referencePanelUrl = job.EnsureReferencePanelUrl();

            string shortId = job.Id.ToString("N")[..8];
            string referencePanelDirectory = Path.Combine(repositoryPath, "downloaded_ref_panel", shortId);
            _ = Directory.CreateDirectory(referencePanelDirectory);

            try
            {
                using HttpClient httpClient = new();

                string fileName = Path.GetFileName(referencePanelUrl.LocalPath);

                if (string.IsNullOrWhiteSpace(fileName))
                {
                    fileName = "reference_panel_" + shortId;
                }

                string targetPath = Path.Combine(referencePanelDirectory, fileName);

                using HttpResponseMessage response = await httpClient.GetAsync(referencePanelUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
                _ = response.EnsureSuccessStatusCode();

                await using FileStream fileStream = File.Create(targetPath);
                await response.Content.CopyToAsync(fileStream, cancellationToken);

                job.ReferencePanelLocalPath = targetPath;

                return referencePanelDirectory;
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Error downloading reference panel from {Url} for job {JobId}", referencePanelUrl, job.Id);
                job.Status = ImputationStatus.Failed;
                job.ErrorMessage = "Failed to download reference panel: " + ex.Message;

                return null;
            }
        }

        private string BuildNextflowCommand(ImputationJob job)
        {
            string repositoryPath = job.RepoWindowsPath ?? string.Empty;
            string repositoryWslPath = repositoryPath.ToWslPath();

            string nextflowCommand = "cd " + repositoryWslPath + " && nextflow run main.nf -c " + job.ConfigRelativePath;

            if (!string.IsNullOrWhiteSpace(job.InputFilesPath))
            {
                string inputWslPath = job.InputFilesPath.ToWslPath();
                if (!inputWslPath.EndsWith("*.vcf.gz", StringComparison.Ordinal) && !inputWslPath.EndsWith('/'))
                {
                    inputWslPath += "/*.vcf.gz";
                }

                _logger.LogInformation("Input files path for job {JobId}: Windows={WindowsPath}, WSL={WslPath}", job.Id, job.InputFilesPath, inputWslPath);

                string windowsInputPath = job.InputFilesPath;
                if (Directory.Exists(windowsInputPath))
                {
                    string[] vcfFiles = Directory.GetFiles(windowsInputPath, "*.vcf.gz", SearchOption.TopDirectoryOnly);
                    _logger.LogInformation("Found {Count} vcf.gz files in {Path} for job {JobId}", vcfFiles.Length, windowsInputPath, job.Id);
                    if (vcfFiles.Length == 0)
                    {
                        _logger.LogWarning("No vcf.gz files found in {Path} for job {JobId}", windowsInputPath, job.Id);
                    }
                }
                else
                {
                    _logger.LogWarning("Input directory does not exist: {Path} for job {JobId}", windowsInputPath, job.Id);
                }

                nextflowCommand += " --files \"" + inputWslPath + "\"";
            }

            if (!string.IsNullOrWhiteSpace(job.ReferencePanelLocalPath))
            {
                string referencePanelWslPath = job.ReferencePanelLocalPath.ToWslPath();
                _logger.LogInformation("Reference panel path for job {JobId}: Windows={WindowsPath}, WSL={WslPath}", job.Id, job.ReferencePanelLocalPath, referencePanelWslPath);
                nextflowCommand += " --reference_panel \"" + referencePanelWslPath + "\"";
            }

            _logger.LogInformation("Running imputation {JobId} in WSL: {Command}", job.Id, nextflowCommand);

            return nextflowCommand;
        }

        private static Task<int> RunNextflowAsync(ImputationJob job, string nextflowCommand, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            string distro = job.Distro ?? DefaultDistro;

            return Task.Run(() => nextflowCommand.RunInWsl(distro), cancellationToken);
        }

        private async Task HandleCompletionAsync(ImputationJob job, int exitCode, CancellationToken cancellationToken)
        {
            if (exitCode == 0)
            {
                job.Status = ImputationStatus.Completed;
                await UploadOutputsToBlobAsync(job, cancellationToken);
            }
            else
            {
                job.Status = ImputationStatus.Failed;
                job.ErrorMessage = "Nextflow exited with code: " + exitCode;
            }
        }

        private async Task UploadOutputsToBlobAsync(ImputationJob job, CancellationToken cancellationToken)
        {
            string repositoryPath = job.RepoWindowsPath ?? string.Empty;
            if (string.IsNullOrWhiteSpace(repositoryPath))
            {
                _logger.LogWarning("Job {JobId} has no repository path; skipping upload of output files to blob storage.", job.Id);

                return;
            }

            string outputDirectory = Path.Combine(repositoryPath, OutputDirectoryName);
            if (!Directory.Exists(outputDirectory))
            {
                _logger.LogWarning("Output directory does not exist for job {JobId}: {Directory}", job.Id, outputDirectory);

                return;
            }

            string containerName = _configuration["Storage:OutputContainer"] ?? "imputation-outputs";
            string prefix = _configuration["Storage:OutputPrefix"] ?? "jobs";
            string jobPrefix = prefix + "/" + job.Id.ToString("N");

            string[] outputFiles = Directory.GetFiles(outputDirectory, "*", SearchOption.AllDirectories);
            foreach (string localFilePath in outputFiles)
            {
                cancellationToken.ThrowIfCancellationRequested();

                string relativePath = Path.GetRelativePath(outputDirectory, localFilePath).Replace('\\', '/');
                string blobName = jobPrefix + "/" + relativePath;
                string blobUrl = await _blobStorageService.UploadFileAsync(containerName, blobName, localFilePath, cancellationToken);
                _logger.LogInformation("Uploaded output file for job {JobId} to blob storage: {BlobUrl}", job.Id, blobUrl);
            }
        }

        private void FailJob(ImputationJob job, Exception exception)
        {
            _logger.LogError(exception, "Error running imputation {JobId}", job.Id);
            job.Status = ImputationStatus.Failed;
            job.ErrorMessage = exception.Message;
        }

        private void CleanupDirectory(string? directoryPath, Guid jobId, string description)
        {
            if (string.IsNullOrWhiteSpace(directoryPath) || !Directory.Exists(directoryPath))
            {
                return;
            }

            try
            {
                Directory.Delete(directoryPath, recursive: true);
                _logger.LogInformation("Cleaned up {Description} for job {JobId}: {Directory}", description, jobId, directoryPath);
            }
            catch (IOException exception)
            {
                _logger.LogWarning(exception, "Failed to clean up {Description} for job {JobId}: {Directory}", description, jobId, directoryPath);
            }
        }
    }
}
