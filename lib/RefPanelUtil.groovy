import org.yaml.snakeyaml.Yaml

class RefPanelUtil {

    public static Object loadFromFile(filename) {

        println "Loading reference panel from file ${filename}..."
        def params_file = new File(filename)
        def parameter_yaml = new FileInputStream(params_file)
        def panel = new Yaml().load(parameter_yaml)
        //todo: replace ${apps_local_folder} and ${apps_hdfs_folder} with parent of params_file

        HashMap<String, String> environment = new HashMap<String, String>();
		def folder = params_file.getParentFile().getAbsolutePath()
		environment.put("app_hdfs_folder", folder);
		environment.put("app_local_folder", folder);
		// Deprecated
		environment.put("hdfs_app_folder", folder);
		environment.put("local_app_folder", folder);

        RefPanelUtil.resolveEnv(panel.properties, environment)
        return panel.properties

    }

    public static void resolveEnv(properties, environment) {
        for (String property : properties.keySet()) {
            Object propertyValue = properties.get(property);
            if (propertyValue instanceof String) {
                propertyValue = RefPanelUtil.env(propertyValue.toString(), environment);
            } else if (propertyValue instanceof Map) {
                resolveEnv(propertyValue, environment);
            }
            properties.put(property, propertyValue);
        }
    }

    public static String env(String value, Map<String, String> variables) {
        def updatedValue = value +"";
        for (String key : variables.keySet()) {
            updatedValue = updatedValue.replaceAll('\\$\\{' + key + '\\}', variables.get(key));
        }
        return updatedValue;
    }

}