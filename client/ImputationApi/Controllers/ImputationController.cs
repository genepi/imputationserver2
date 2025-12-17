using ImputationApi.Extensions;
using ImputationApi.Models;
using ImputationApi.Services;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
using System.Diagnostics.CodeAnalysis;

namespace ImputationApi.Controllers
{
    [ApiController]
    [Route("imputations")]
    public class ImputationController(ILogger<ImputationController> logger, IConfiguration configuration, IImputationService imputationService) : ControllerBase
    {
        private const string DefaultDistro = "Ubuntu";
        private const string OutputDirectoryName = "output";

        private static readonly ConcurrentDictionary<Guid, ImputationJob> Jobs = new();

        private readonly ILogger<ImputationController> _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        private readonly IConfiguration _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        private readonly IImputationService _imputationService = imputationService ?? throw new ArgumentNullException(nameof(imputationService));

        [HttpPost]
        public ActionResult<ImputationJob> Create([FromBody] ImputationRequest request)
        {
            Guid id = Guid.NewGuid();

            if (request is null)
            {
                return BadRequest("Request body is required.");
            }

            if (!TryResolveConfig(request, out string? configName, out string configRelativePath, out string? configError))
            {
                return BadRequest(configError);
            }

            string repoWindowsPath;
            try
            {
                repoWindowsPath = _imputationService.ResolveRepositoryWindowsPath();
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
                RepoWindowsPath = repoWindowsPath.NormalizeWindowsPath(),
                ConfigName = configName,
                ConfigRelativePath = configRelativePath,
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

            _ = Task.Run(() => _imputationService.RunAsync(job, CancellationToken.None));

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
                }).ToList();

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

        private bool TryResolveConfig(ImputationRequest request, out string? configName, out string configRelativePath, out string? error)
        {
            configName = null;
            configRelativePath = string.Empty;
            error = null;

            string? requestedConfigName = request.ConfigName;
            if (!string.IsNullOrWhiteSpace(requestedConfigName))
            {
                string? mappedRelativePath = _configuration["Imputation:ConfigMap:" + requestedConfigName];
                if (string.IsNullOrWhiteSpace(mappedRelativePath))
                {
                    error = "Unknown ConfigName: " + requestedConfigName;

                    return false;
                }

                if (!mappedRelativePath.IsSafeRelativePath())
                {
                    error = "Invalid config path mapping for ConfigName: " + requestedConfigName;

                    return false;
                }

                configName = requestedConfigName;
                configRelativePath = mappedRelativePath;

                return true;
            }

            string? requestedRelativePath = request.ConfigRelativePath;
            if (string.IsNullOrWhiteSpace(requestedRelativePath))
            {
                error = "ConfigName or ConfigRelativePath is required.";

                return false;
            }

            if (!requestedRelativePath.IsSafeRelativePath())
            {
                error = "ConfigRelativePath must be a safe relative path.";

                return false;
            }

            configRelativePath = requestedRelativePath;

            return true;
        }
    }
}
