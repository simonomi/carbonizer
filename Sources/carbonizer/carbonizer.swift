import ArgumentParser
import Foundation

var standardError = FileHandle.standardError

var extractMARs: ExtractMARs = .auto
var inputPackedStatus = InputPackedStatus.unknown

enum ExtractMARs: String, ExpressibleByArgument {
	case always, never, auto
	
	var shouldExtract: Bool {
		self == .always || self == .auto
	}
	
	mutating func replaceAuto(with newValue: Self) {
		if self == .auto {
			self = newValue
		}
	}
}

enum InputPackedStatus {
	case unknown, packed, unpacked, contradictory
	
	var wasPacked: Bool? {
		switch self {
			case .packed: true
			case .unpacked: false
			default: nil
		}
	}
	
	mutating func set(to newValue: Self, ignoreContradiction: Bool = false) {
		if self == .unknown {
			self = newValue
		} else if self != newValue && !ignoreContradiction {
			self = .contradictory
		}
	}
}

@main
struct carbonizer: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool.",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode")
	var compressionMode: CompressionMode?
	
	@Option(name: [.short, .customLong("extract-mars")], help: "Whether to extract MAR files. Options are always, never, auto")
	var extractMARsInput: ExtractMARs = .auto
	
	@Argument(help: "The files to pack/unpack", transform: URL.fromFilePath)
	var filePaths = [URL]()
	
	enum CompressionMode: String, EnumerableFlag {
		case pack, unpack
		
		static func name(for value: Self) -> NameSpecification {
			.shortAndLong
		}
	}
	
	mutating func run() throws {
#if !IN_CI
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters/data/motion/ui_option/"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"))
#endif
		
		extractMARs = extractMARsInput
		
		// TODO: document this
#if os(Windows)
		let extractMARsOptionFile = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("extract mars.txt")
#else
		let extractMARsOptionFile = URL.currentDirectory().appending(component: "extract mars.txt")
#endif
		if let extractMARsOverride = (try? String(contentsOf: extractMARsOptionFile))
			.flatMap(ExtractMARs.init), extractMARs == .auto {
			extractMARs = extractMARsOverride
		}
		
#if !IN_CI
		extractMARs = .always
#endif
		
		if filePaths.isEmpty {
			print("\(.red, .bold)Error:\(.normal) \(.bold)No files were specified as input\(.normal)", terminator: "\n\n", to: &standardError)
			print(Self.helpMessage())
			waitForInput()
			return
		}
		
		for filePath in filePaths {
			inputPackedStatus = .unknown
			
			var file = try CreateFileSystemObject(contentsOf: filePath)
			
#if !IN_CI
//			file = try file.postProcessed(with: mm3Finder)
//			file = try file.postProcessed(with: mpmFinder) // doesnt work for much
			file = try file.postProcessed(with: mmsFinder)
//			return
#endif
			
#if IN_CI
			let outputDirectory = filePath.deletingLastPathComponent()
#else
			let outputDirectory = URL(filePath: "/Users/simonomi/ff1/output/")
#endif
			
#if !IN_CI
			inputPackedStatus = .packed
#endif
			
			if let wasPacked = inputPackedStatus.wasPacked {
				try file.write(into: outputDirectory, packed: !wasPacked)
			} else {
				print("Would you like to [P]ack or [U]npack? ")
				guard let answer = readLine()?.lowercased() else { return }
				
				if answer.starts(with: "p") {
					try file.write(into: outputDirectory, packed: true)
				} else if answer.starts(with: "u") {
					try file.write(into: outputDirectory, packed: false)
				} else {
					return
				}
			}
		}
	}
}
