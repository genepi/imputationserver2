using System.Text.Json.Serialization;

namespace ImputationApi.Models
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum ImputationStatus
    {
        Pending,
        Running,
        Completed,
        Failed
    }
}
