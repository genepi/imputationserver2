using System.Collections.ObjectModel;

namespace ImputationApi.Models
{
    public class ImputationRequest
    {
        public string? ConfigName { get; set; }

        public string? ConfigRelativePath { get; set; }

        public Collection<Uri>? DownloadUrls { get; set; }

        public Uri? ReferencePanelDownloadUrl { get; set; }
    }
}
