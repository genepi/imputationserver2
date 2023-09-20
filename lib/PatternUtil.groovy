class PatternUtil {

    public static String parse(String value, Map<String, Object> variables) {
        def updatedValue = value +"";
        for (String key : variables.keySet()) {
            updatedValue = updatedValue.replaceAll('\\$\\{' + key + '\\}', variables.get(key).toString());
             updatedValue = updatedValue.replaceAll('\\$' + key, variables.get(key).toString());
        }
        return updatedValue;
    }
}