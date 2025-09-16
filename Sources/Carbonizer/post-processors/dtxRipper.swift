enum DTXRipError: Error, CustomStringConvertible {
	case marNotUnpacked
	case dtxNotUnpacked
	
	var description: String {
		switch self {
			case .marNotUnpacked:
				"the MAR file type was not unpacked"
			case .dtxNotUnpacked:
				"the DTX file type was not unpacked"
		}
	}
}

func dtxRipper(_ fileSystemObject: any FileSystemObject) throws(DTXRipError) -> [String] {
	let nds = fileSystemObject as! NDS.Unpacked
	let text = nds.contents.first { $0.name == "text" } as! Folder
	guard let japanese = text.contents.first(where: { $0.name == "japanese" })! as? MAR.Unpacked else {
		throw .marNotUnpacked
	}
	
	guard let dtx = japanese.files.first!.content as? DTX.Unpacked else {
		throw .dtxNotUnpacked
	}
	
	return dtx.strings
}
