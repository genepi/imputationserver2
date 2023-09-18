import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter


public class CloudgeneReport {

	def filename

	def events = []

	public CloudgeneReport() {
		this("cloudgene.report.json")
	}

	public CloudgeneReport(String filename) {
		this.filename = filename
	}

	public void ok(String message) {
		def event = [
			command: "MESSAGE",
			params: [message, 0]
		]
		events.add(event)
		save();
	}

	public void error(String message) {
		def event = [
			command: "MESSAGE",
			params: [message, 1]
		]
		events.add(event)
		save();
	}

	public void save() {
		def jsonOutput = new JsonGenerator.Options().build()
		new File(filename).text = jsonOutput.toJson(events)
	}
	
}
