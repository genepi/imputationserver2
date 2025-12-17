namespace ImputationApi.Extensions
{
    public static class ImputationJobExtensions
    {
        public static string EnsureRepositoryPath(this Models.ImputationJob job)
        {
            ArgumentNullException.ThrowIfNull(job);

            return string.IsNullOrWhiteSpace(job.RepoWindowsPath)
                ? throw new InvalidOperationException("Job does not have a repository path.")
                : job.RepoWindowsPath;
        }

        public static Uri EnsureReferencePanelUrl(this Models.ImputationJob job)
        {
            ArgumentNullException.ThrowIfNull(job);

            return job.ReferencePanelDownloadUrl
                ?? throw new InvalidOperationException("Job does not have a reference panel download URL.");
        }
    }
}
