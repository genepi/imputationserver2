namespace ImputationApi.Extensions
{
    public static class WindowsPathExtensions
    {
        public static string NormalizeWindowsPath(this string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return path ?? string.Empty;
            }

            string normalized = path.Replace('\\', '/');

            if (normalized.Length >= 2 && char.IsLetter(normalized[0]))
            {
                if (normalized[1] == '/')
                {
                    normalized = char.ToUpperInvariant(normalized[0]) + ":" + normalized[1..];
                }
                else if (normalized[1] == ':')
                {
                    normalized = char.ToUpperInvariant(normalized[0]) + normalized[1..];
                }
            }

            return normalized;
        }

        public static string ToWslPath(this string windowsPath)
        {
            if (string.IsNullOrWhiteSpace(windowsPath))
            {
                return windowsPath ?? string.Empty;
            }

            string normalized = windowsPath.NormalizeWindowsPath();

            if (normalized.Length >= 2 && char.IsLetter(normalized[0]) && normalized[1] == ':')
            {
                string drive = normalized[..1].ToLowerInvariant();
                string remainder = normalized[2..];
                return remainder.StartsWith('/') ? "/mnt/" + drive + remainder : "/mnt/" + drive + "/" + remainder;
            }

            return normalized;
        }
    }
}
