namespace ImputationApi.Models
{
    public class ImputationRequest
    {
        public string? ConfigRelativePath { get; set; }

        public List<string>? DownloadUrls { get; set; }

        public Uri? ReferencePanelDownloadUrl { get; set; }
    }
}
