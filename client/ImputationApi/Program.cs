using ImputationApi.Services;
using Microsoft.Extensions.Logging.ApplicationInsights;

namespace ImputationApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

            builder.Services.AddApplicationInsightsTelemetry();
            builder.Logging.AddFilter<ApplicationInsightsLoggerProvider>("", LogLevel.Information);

            builder.Services.AddControllers();
            builder.Services.AddSingleton<IBlobStorageService, BlobStorageService>();
            builder.Services.AddSingleton<IImputationService, ImputationService>();

            WebApplication app = builder.Build();

            app.UseHttpsRedirection();

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
