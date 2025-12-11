using ImputationApi.Models;
using ImputationApi.Services;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;

namespace ImputationApi.Controllers
{
    [ApiController]
    [Route("imputations")]
    public class ImputationController(ILogger<ImputationController> logger, IConfiguration configuration, IWebHostEnvironment environment, IBlobStorageService blobStorageService) : ControllerBase
    {
        private const string DefaultDistro = "Ubuntu";
        private const string OutputDirectoryName = "output";

        private static readonly ConcurrentDictionary<Guid, ImputationJob> Jobs = new();

        private readonly ILogger<ImputationController> _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        private readonly IConfiguration _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        private readonly IWebHostEnvironment _environment = environment ?? throw new ArgumentNullException(nameof(environment));
        private readonly IBlobStorageService _blobStorageService = blobStorageService ?? throw new ArgumentNullException(nameof(blobStorageService));

        [HttpPost]
        public ActionResult<ImputationJob> Create([FromBody] ImputationRequest request)
        {
            Guid id = Guid.NewGuid();

            if (request is null)
            {
                return BadRequest("Request body is required.");
            }

            if (string.IsNullOrWhiteSpace(request.ConfigRelativePath))
            {
                return BadRequest("ConfigRelativePath is required.");
            }

            string repoWindowsPath;
            try
            {
                repoWindowsPath = GetRepositoryWindowsPath();
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Failed to resolve repository path for imputation job {JobId}", id);
                return StatusCode(500, "Failed to resolve repository path: " + ex.Message);
            }

            string distro = _configuration["Imputation:Distro"] ?? DefaultDistro;

            ImputationJob job = new()
            {
                Id = id,
                Status = ImputationStatus.Pending,
                CreatedAt = DateTimeOffset.UtcNow,
                RepoWindowsPath = NormalizeWindowsPath(repoWindowsPath),
                ConfigRelativePath = request.ConfigRelativePath,
                InputFilesPath = string.Empty,
                DownloadUrls = request.DownloadUrls is { Count: > 0 } ? [.. request.DownloadUrls] : null,
                ReferencePanelDownloadUrl = request.ReferencePanelDownloadUrl,
                Distro = string.IsNullOrWhiteSpace(distro) ? DefaultDistro : distro,
            };

            if (!Directory.Exists(job.RepoWindowsPath))
            {
                job.Status = ImputationStatus.Failed;
                job.ErrorMessage = "Repository path not found: " + job.RepoWindowsPath;
                job.FinishedAt = DateTimeOffset.UtcNow;
                Jobs[id] = job;
                return BadRequest(job);
            }

            Jobs[id] = job;

            _ = Task.Run(() => RunImputationAsync(job));

            return CreatedAtAction(nameof(GetById), new { id }, job);
        }

        [HttpGet("{id:guid}")]
        public ActionResult<ImputationJob> GetById(Guid id)
        {
            return !TryGetJob(id, out ImputationJob? job, out ActionResult result) ? (ActionResult<ImputationJob>)result : (ActionResult<ImputationJob>)Ok(job);
        }

        [HttpGet("{id:guid}/status")]
        public ActionResult<object> GetStatus(Guid id)
        {
            return !TryGetJob(id, out ImputationJob? job, out ActionResult result) ? (ActionResult<object>)result : (ActionResult<object>)Ok(new
            {
                job.Id,
                job.Status,
                job.ExitCode,
                job.ErrorMessage
            });
        }

        [HttpGet("{id:guid}/output")]
        public ActionResult<object> GetOutputFiles(Guid id)
        {
            if (!TryGetJob(id, out ImputationJob? job, out ActionResult result))
            {
                return result;
            }

            if (string.IsNullOrWhiteSpace(job.RepoWindowsPath))
            {
                return BadRequest("Job does not have a repository path.");
            }

            string outputDir = Path.Combine(job.RepoWindowsPath, OutputDirectoryName);

            if (!Directory.Exists(outputDir))
            {
                return NotFound("Output directory not found: " + outputDir);
            }

            var files = Directory.GetFiles(outputDir, "*", SearchOption.AllDirectories)
                .Select(path => new
                {
                    Name = Path.GetFileName(path),
                    RelativePath = Path.GetRelativePath(outputDir, path),
                    FullPath = path,
                    SizeBytes = new FileInfo(path).Length,
                    LastModified = System.IO.File.GetLastWriteTimeUtc(path),
                    Extension = Path.GetExtension(path)
                })
                .ToList();

            int? inputFilesCount = null;
            if (!string.IsNullOrWhiteSpace(job.InputFilesPath) && Directory.Exists(job.InputFilesPath))
            {
                inputFilesCount = Directory.GetFiles(job.InputFilesPath, "*.vcf.gz", SearchOption.TopDirectoryOnly).Length;
            }

            long totalSize = files.Sum(file => file.SizeBytes);

            return Ok(new
            {
                TotalFiles = files.Count,
                TotalSizeBytes = totalSize,
                TotalSizeMB = Math.Round(totalSize / (1024.0 * 1024.0), 2),
                InputFilesCount = inputFilesCount,
                OutputDirectory = outputDir,
                Files = files
            });
        }

        private async Task RunImputationAsync(ImputationJob job)
        {
            string? downloadDirectory = null;
            string? referencePanelDirectory = null;

            try
            {
                job.Status = ImputationStatus.Running;

                string repositoryPath = EnsureRepositoryPath(job);

                if (job.DownloadUrls is { Count: > 0 })
                {
                    downloadDirectory = await DownloadInputFilesAsync(job, repositoryPath);
                    if (downloadDirectory == null)
                    {
                        return;
                    }
                }

                if (job.ReferencePanelDownloadUrl != null)
                {
                    referencePanelDirectory = await DownloadReferencePanelAsync(job, repositoryPath);
                    if (referencePanelDirectory == null)
                    {
                        return;
                    }
                }

                string nextflowCommand = BuildNextflowCommand(job);
                int exitCode = await RunNextflowAsync(job, nextflowCommand);
                job.ExitCode = exitCode;

                await HandleCompletionAsync(job, exitCode);
            }
            catch (Exception ex)
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

        private static string EnsureRepositoryPath(ImputationJob job)
        {
            return string.IsNullOrWhiteSpace(job.RepoWindowsPath) ? throw new InvalidOperationException("Job does not have a repository path.") : job.RepoWindowsPath;
        }

        private static Uri EnsureReferencePanelUrl(ImputationJob job)
        {
            return job.ReferencePanelDownloadUrl ?? throw new InvalidOperationException("Job does not have a reference panel download URL.");
        }

        private async Task<string?> DownloadInputFilesAsync(ImputationJob job, string repositoryPath)
        {
            string shortId = job.Id.ToString("N")[..8];
            string downloadDirectory = Path.Combine(repositoryPath, "downloaded", shortId);
            _ = Directory.CreateDirectory(downloadDirectory);

            using HttpClient httpClient = new();

            foreach (string url in job.DownloadUrls!)
            {
                if (string.IsNullOrWhiteSpace(url))
                {
                    continue;
                }

                try
                {
                    Uri uri = new(url);
                    string fileName = Path.GetFileName(uri.LocalPath);

                    if (string.IsNullOrWhiteSpace(fileName))
                    {
                        fileName = Guid.NewGuid().ToString("N") + ".vcf.gz";
                    }

                    string targetPath = Path.Combine(downloadDirectory, fileName);

                    using HttpResponseMessage response = await httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead);
                    _ = response.EnsureSuccessStatusCode();

                    await using FileStream fileStream = System.IO.File.Create(targetPath);
                    await response.Content.CopyToAsync(fileStream);
                }
                catch (HttpRequestException ex)
                {
                    _logger.LogError(ex, "Error downloading file from {Url} for job {JobId}", url, job.Id);
                    job.Status = ImputationStatus.Failed;
                    job.ErrorMessage = "Failed to download " + url + ": " + ex.Message;
                    return null;
                }
            }

            job.InputFilesPath = downloadDirectory;
            return downloadDirectory;
        }

        private async Task<string?> DownloadReferencePanelAsync(ImputationJob job, string repositoryPath)
        {
            Uri referencePanelUrl = EnsureReferencePanelUrl(job);

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

                using HttpResponseMessage response = await httpClient.GetAsync(referencePanelUrl, HttpCompletionOption.ResponseHeadersRead);
                _ = response.EnsureSuccessStatusCode();

                await using FileStream fileStream = System.IO.File.Create(targetPath);
                await response.Content.CopyToAsync(fileStream);

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
            string repositoryWslPath = ToWslPath(repositoryPath);

            string nextflowCommand = "cd " + repositoryWslPath + " && nextflow run main.nf -c " + job.ConfigRelativePath;

            if (!string.IsNullOrWhiteSpace(job.InputFilesPath))
            {
                string inputWslPath = ToWslPath(job.InputFilesPath);
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
                string referencePanelWslPath = ToWslPath(job.ReferencePanelLocalPath);
                _logger.LogInformation("Reference panel path for job {JobId}: Windows={WindowsPath}, WSL={WslPath}", job.Id, job.ReferencePanelLocalPath, referencePanelWslPath);
                nextflowCommand += " --reference_panel \"" + referencePanelWslPath + "\"";
            }

            _logger.LogInformation("Running imputation {JobId} in WSL: {Command}", job.Id, nextflowCommand);

            return nextflowCommand;
        }

        private static Task<int> RunNextflowAsync(ImputationJob job, string nextflowCommand)
        {
            return Task.Run(() => RunInWsl(nextflowCommand, job.Distro ?? DefaultDistro));
        }

        private async Task HandleCompletionAsync(ImputationJob job, int exitCode)
        {
            if (exitCode == 0)
            {
                job.Status = ImputationStatus.Completed;
                await UploadOutputsToBlobAsync(job);
            }
            else
            {
                job.Status = ImputationStatus.Failed;
                job.ErrorMessage = "Nextflow exited with code: " + exitCode;
            }
        }

        private async Task UploadOutputsToBlobAsync(ImputationJob job)
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

            try
            {
                string[] outputFiles = Directory.GetFiles(outputDirectory, "*", SearchOption.AllDirectories);
                foreach (string filePath in outputFiles)
                {
                    string relativePath = Path.GetRelativePath(outputDirectory, filePath).Replace('\\', '/');
                    string blobName = jobPrefix + "/" + relativePath;
                    string blobUrl = await _blobStorageService.UploadFileAsync(containerName, blobName, filePath, CancellationToken.None);
                    _logger.LogInformation("Uploaded output file for job {JobId} to blob storage: {BlobUrl}", job.Id, blobUrl);
                }
            }
            catch (Azure.RequestFailedException uploadException)
            {
                _logger.LogError(uploadException, "Failed to upload output files for job {JobId} to blob storage.", job.Id);
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

        private static string NormalizeWindowsPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return path ?? string.Empty;
            }

            string normalized = path.Replace('\\', '/');

            if (normalized.Length >= 2 && char.IsLetter(normalized[0]))
            {
                if (normalized[1] == '/')
                {
                    normalized = char.ToUpperInvariant(normalized[0]) + ":" + normalized[1..];
                }
                else if (normalized[1] == ':')
                {
                    normalized = char.ToUpperInvariant(normalized[0]) + normalized[1..];
                }
            }

            return normalized;
        }

        private string GetRepositoryWindowsPath()
        {
            string contentRootPath = _environment.ContentRootPath;
            DirectoryInfo? clientDirectory = Directory.GetParent(contentRootPath) ?? throw new InvalidOperationException("Unable to resolve client directory from content root path: " + contentRootPath);
            DirectoryInfo? repositoryRootDirectory = clientDirectory.Parent;
            return repositoryRootDirectory == null
                ? throw new InvalidOperationException("Unable to resolve repository root directory from client directory: " + clientDirectory.FullName)
                : repositoryRootDirectory.FullName;
        }

        private static string ToWslPath(string windowsPath)
        {
            if (string.IsNullOrWhiteSpace(windowsPath))
            {
                return windowsPath ?? string.Empty;
            }

            string normalized = NormalizeWindowsPath(windowsPath);

            if (normalized.Length >= 2 && char.IsLetter(normalized[0]) && normalized[1] == ':')
            {
                string drive = normalized[..1].ToLowerInvariant();
                string remainder = normalized[2..];
                return remainder.StartsWith('/') ? "/mnt/" + drive + remainder : "/mnt/" + drive + "/" + remainder;
            }

            return normalized;
        }

        private bool TryGetJob(Guid id, [NotNullWhen(true)] out ImputationJob? job, out ActionResult result)
        {
            if (Jobs.TryGetValue(id, out job))
            {
                result = null!;
                return true;
            }

            job = null;
            result = NotFound();
            return false;
        }

        private static int RunInWsl(string command, string distro)
        {
            string escaped = command.Replace("\"", "\\\"", StringComparison.Ordinal);
            string bash = "bash -lc \"" + escaped + "\"";
            string arguments = string.IsNullOrWhiteSpace(distro) ? bash : "-d " + distro + " -- " + bash;

            ProcessStartInfo info = new()
            {
                FileName = "wsl",
                Arguments = arguments,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = false
            };

            using Process process = new();
            process.StartInfo = info;

            process.OutputDataReceived += (_, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    Console.WriteLine(e.Data);
                }
            };

            process.ErrorDataReceived += (_, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    Console.Error.WriteLine(e.Data);
                }
            };

            bool started = process.Start();

            if (!started)
            {
                Console.Error.WriteLine("Failed to start WSL process.");
                return 1;
            }

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            process.WaitForExit();
            return process.ExitCode;
        }
    }
}
