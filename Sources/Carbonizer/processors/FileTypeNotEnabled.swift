struct FileTypeNotEnabled: Error, CustomStringConvertible {
	var fileType: String
	var processor: Processor
	
	var description: String {
		"file type \(.red)\(fileType)\(.normal) needs to be enabled for \(.cyan)\(processor.name)\(.normal) to run"
	}
}
