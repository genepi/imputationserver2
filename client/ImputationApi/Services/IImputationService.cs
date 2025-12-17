using ImputationApi.Models;

namespace ImputationApi.Services
{
    public interface IImputationService
    {
        string ResolveRepositoryWindowsPath();

        Task RunAsync(ImputationJob job, CancellationToken cancellationToken);
    }
}
