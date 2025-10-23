import Foundation

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting...) {
		self.init()
		outputFormatting = OutputFormatting(formatting)
	}
}

extension JSONDecoder {
	convenience init(allowsJSON5: Bool) {
		self.init()
		self.allowsJSON5 = allowsJSON5
	}
}
