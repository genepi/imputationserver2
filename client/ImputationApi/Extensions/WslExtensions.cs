using System.Diagnostics;

namespace ImputationApi.Extensions
{
    public static class WslExtensions
    {
        public static int RunInWsl(this string command, string distro)
        {
            if (string.IsNullOrWhiteSpace(command))
            {
                throw new ArgumentException("Command is required.", nameof(command));
            }

            string escaped = command.Replace("\"", "\\\"", StringComparison.Ordinal);
            string bash = "bash -lc \"" + escaped + "\"";
            string arguments = string.IsNullOrWhiteSpace(distro) ? bash : "-d " + distro + " -- " + bash;

            ProcessStartInfo info = new()
            {
                FileName = "wsl",
                Arguments = arguments,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = false
            };

            using Process process = new();
            process.StartInfo = info;

            process.OutputDataReceived += (_, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    Console.WriteLine(e.Data);
                }
            };

            process.ErrorDataReceived += (_, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    Console.Error.WriteLine(e.Data);
                }
            };

            bool started = process.Start();

            if (!started)
            {
                Console.Error.WriteLine("Failed to start WSL process.");

                return 1;
            }

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            process.WaitForExit();

            return process.ExitCode;
        }
    }
}
