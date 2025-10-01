public class GlobalJsonData {
    // Static/global variable holding the parsed JSON
    public static Json.Node? parsed_data = null;

    public static void load_json(string filename) {
        try {
            string json_text;
            FileUtils.get_contents(filename, out json_text);
            Json.Parser parser = new Json.Parser();
            parser.load_from_data(json_text);
            parsed_data = parser.get_root();
        } catch (Error e) {
            stderr.printf("Failed to load JSON: %s\n", e.message);
        }
    }
}

