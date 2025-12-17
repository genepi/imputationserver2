namespace ImputationApi.Extensions
{
    public static class PathSafetyExtensions
    {
        public static bool IsSafeRelativePath(this string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return false;
            }

            if (Path.IsPathRooted(path))
            {
                return false;
            }

            string[] segments = path.Split(['/', '\\'], StringSplitOptions.RemoveEmptyEntries);
            foreach (string segment in segments)
            {
                if (string.Equals(segment, "..", StringComparison.Ordinal))
                {
                    return false;
                }
            }

            return true;
        }
    }
}
