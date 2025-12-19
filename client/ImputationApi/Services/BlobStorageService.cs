using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.ApplicationInsights;
using System.Globalization;

namespace ImputationApi.Services
{
    public sealed class BlobStorageService : IBlobStorageService
    {
        private readonly BlobServiceClient _blobServiceClient;
        private readonly TelemetryClient? _telemetryClient;
        private readonly ILogger<BlobStorageService> _logger;

        public BlobStorageService(IConfiguration configuration, ILogger<BlobStorageService> logger, TelemetryClient? telemetryClient = null)
        {
            ArgumentNullException.ThrowIfNull(configuration);
            ArgumentNullException.ThrowIfNull(logger);

            _telemetryClient = telemetryClient;
            _logger = logger;

            string? connectionString = configuration["Storage:ConnectionString"];
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Storage:ConnectionString configuration is required.");
            }

            _blobServiceClient = new BlobServiceClient(connectionString);
        }

        public async Task<string> UploadFileAsync(string containerName, string blobName, string localFilePath, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(containerName))
            {
                throw new ArgumentException("Container name is required.", nameof(containerName));
            }

            if (string.IsNullOrWhiteSpace(blobName))
            {
                throw new ArgumentException("Blob name is required.", nameof(blobName));
            }

            if (string.IsNullOrWhiteSpace(localFilePath))
            {
                throw new ArgumentException("Local file path is required.", nameof(localFilePath));
            }

            if (!File.Exists(localFilePath))
            {
                throw new FileNotFoundException("File to upload was not found.", localFilePath);
            }

            FileInfo fileInfo = new(localFilePath);
            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            Response<BlobContainerInfo>? createContainerResponse = await containerClient.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

            bool created = createContainerResponse is not null;
            Dictionary<string, string> createContainerProperties = new()
            {
                { "ContainerName", containerName },
                { "Created", created ? "true" : "false" },
                { "ContainerUri", containerClient.Uri.AbsoluteUri },
            };

            if (createContainerResponse is not null)
            {
                Response rawCreateResponse = createContainerResponse.GetRawResponse();
                createContainerProperties["Status"] = rawCreateResponse.Status.ToString(CultureInfo.InvariantCulture);

                if (rawCreateResponse.Headers.TryGetValue("x-ms-request-id", out string? requestId) && !string.IsNullOrWhiteSpace(requestId))
                {
                    createContainerProperties["RequestId"] = requestId;
                }

                if (rawCreateResponse.Headers.TryGetValue("x-ms-client-request-id", out string? clientRequestId) && !string.IsNullOrWhiteSpace(clientRequestId))
                {
                    createContainerProperties["ClientRequestId"] = clientRequestId;
                }
            }

            _telemetryClient?.TrackEvent("Blob.Container.CreateIfNotExists", createContainerProperties);
            _logger.LogInformation("Blob container ensured. ContainerName={ContainerName} Created={Created}", containerName, created);

            BlobClient blobClient = containerClient.GetBlobClient(blobName);

            await using FileStream fileStream = File.OpenRead(localFilePath);
            Response<BlobContentInfo> uploadResponse = await blobClient.UploadAsync(fileStream, overwrite: true, cancellationToken);

            Response rawUploadResponse = uploadResponse.GetRawResponse();
            BlobContentInfo uploadInfo = uploadResponse.Value;

            Dictionary<string, string> uploadProperties = new()
            {
                { "ContainerName", containerName },
                { "BlobName", blobName },
                { "BlobUri", blobClient.Uri.AbsoluteUri },
                { "FileName", Path.GetFileName(localFilePath) },
                { "Status", rawUploadResponse.Status.ToString(CultureInfo.InvariantCulture) },
            };

            if (rawUploadResponse.Headers.TryGetValue("x-ms-request-id", out string? uploadRequestId) && !string.IsNullOrWhiteSpace(uploadRequestId))
            {
                uploadProperties["RequestId"] = uploadRequestId;
            }

            if (rawUploadResponse.Headers.TryGetValue("x-ms-client-request-id", out string? uploadClientRequestId) && !string.IsNullOrWhiteSpace(uploadClientRequestId))
            {
                uploadProperties["ClientRequestId"] = uploadClientRequestId;
            }

            uploadProperties["ETag"] = uploadInfo.ETag.ToString();

            Dictionary<string, double> uploadMetrics = new()
            {
                { "FileSizeBytes", fileInfo.Length },
            };

            _telemetryClient?.TrackEvent("Blob.Upload", uploadProperties, uploadMetrics);
            _logger.LogInformation("Blob uploaded. ContainerName={ContainerName} BlobName={BlobName} Status={Status} ETag={ETag} FileSizeBytes={FileSizeBytes}",
                containerName,
                blobName,
                rawUploadResponse.Status,
                uploadInfo.ETag.ToString(),
                fileInfo.Length);

            return blobClient.Uri.AbsoluteUri;
        }
    }
}
