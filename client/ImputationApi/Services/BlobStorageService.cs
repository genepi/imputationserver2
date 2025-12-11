using Azure.Storage.Blobs;

namespace ImputationApi.Services
{
    public sealed class BlobStorageService : IBlobStorageService
    {
        private readonly BlobServiceClient _blobServiceClient;

        public BlobStorageService(IConfiguration configuration)
        {
            ArgumentNullException.ThrowIfNull(configuration);

            string? connectionString = configuration["Storage:ConnectionString"];
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Storage:ConnectionString configuration is required.");
            }

            _blobServiceClient = new BlobServiceClient(connectionString);
        }

        public async Task<string> UploadFileAsync(string containerName, string blobName, string filePath, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(containerName))
            {
                throw new ArgumentException("Container name is required.", nameof(containerName));
            }

            if (string.IsNullOrWhiteSpace(blobName))
            {
                throw new ArgumentException("Blob name is required.", nameof(blobName));
            }

            if (string.IsNullOrWhiteSpace(filePath))
            {
                throw new ArgumentException("File path is required.", nameof(filePath));
            }

            if (!File.Exists(filePath))
            {
                throw new FileNotFoundException("File to upload was not found.", filePath);
            }

            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            _ = await containerClient.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

            BlobClient blobClient = containerClient.GetBlobClient(blobName);

            await using FileStream fileStream = File.OpenRead(filePath);
            _ = await blobClient.UploadAsync(fileStream, overwrite: true, cancellationToken);

            return blobClient.Uri.AbsoluteUri;
        }
    }
}
