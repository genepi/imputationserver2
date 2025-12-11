namespace ImputationApi.Services
{
    public interface IBlobStorageService
    {
        Task<string> UploadFileAsync(string containerName, string blobName, string filePath, CancellationToken cancellationToken);
    }
}
