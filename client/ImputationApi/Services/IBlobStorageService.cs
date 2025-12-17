namespace ImputationApi.Services
{
    public interface IBlobStorageService
    {
        Task<string> UploadFileAsync(string containerName, string blobName, string localFilePath, CancellationToken cancellationToken);
    }
}
