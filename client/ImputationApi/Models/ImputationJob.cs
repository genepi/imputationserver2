namespace ImputationApi.Models
{
    public class ImputationJob
    {
        public Guid Id { get; set; }

        public ImputationStatus Status { get; set; }

        public int? ExitCode { get; set; }

        public string? ErrorMessage { get; set; }

        public DateTimeOffset CreatedAt { get; set; }

        public DateTimeOffset? FinishedAt { get; set; }

        public string? RepoWindowsPath { get; set; }

        public string? ConfigName { get; set; }

        public string? ConfigRelativePath { get; set; }

        public string? InputFilesPath { get; set; }

        public IReadOnlyCollection<Uri>? DownloadUrls { get; set; }

        public Uri? ReferencePanelDownloadUrl { get; set; }

        public string? ReferencePanelLocalPath { get; set; }

        public string? Distro { get; set; }
    }
}
