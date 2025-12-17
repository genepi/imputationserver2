using ImputationApi.Services;

namespace ImputationApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

            string? instrumentationKey = builder.Configuration["Telemetry:InstrumentationKey"];
            builder.Services.AddApplicationInsightsTelemetry(options =>
            {
                options.ConnectionString = string.IsNullOrWhiteSpace(instrumentationKey) ? null : "InstrumentationKey=" + instrumentationKey;
            });

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
