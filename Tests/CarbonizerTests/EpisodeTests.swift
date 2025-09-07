import Testing
import Foundation

@testable import Carbonizer

@Test(arguments: [DEX.Unpacked.ff1Commands, DEX.Unpacked.ffcCommands])
func knownCommandsAreValid(commandList: [UInt32: DEX.Unpacked.CommandDefinition]) throws {
	var allCommandsWithoutArguments = Set<[String]>()
	
	for command in commandList.values {
		guard !allCommandsWithoutArguments.contains(command.textWithoutArguments) else {
			try Issue.failure("\(ANSIFontEffect.red)duplicate command text for \(command.textWithoutArguments) >:(\(ANSIFontEffect.normal)")
		}
		allCommandsWithoutArguments.insert(command.textWithoutArguments)
	}
}

@Test
func checkKnownRequirements() throws {
	var allRequirementsWithoutArguments = Set<[String]>()
	
	for requirement in DEP.Unpacked.knownRequirements.values {
		guard !allRequirementsWithoutArguments.contains(requirement.textWithoutArguments) else {
			try Issue.failure("\(ANSIFontEffect.red)duplicate command text for \(requirement.textWithoutArguments) >:(\(ANSIFontEffect.normal)")
		}
		allRequirementsWithoutArguments.insert(requirement.textWithoutArguments)
	}
}

@Test(
//	.disabled("only enable when needed")
)
func exportDEXCommands() throws {
	struct Command: Encodable {
		var id: UInt32
		var command: String
	}
	
	let result = DEX.Unpacked.ff1Commands
		.sorted(by: \.key)
		.map { Command(id: $0, command: $1.formatted()) }
	
	let outputPath = URL(filePath: "/tmp/commands.json")
	try JSONEncoder().encode(result).write(to: outputPath)
	
	print("\(.cyan)DEX commands written to \(outputPath.path(percentEncoded: false))\(.normal)")
}

extension DEX.Unpacked.CommandDefinition {
	func formatted() -> String {
		outputStringThingy
			.map {
				switch $0 {
					case .text(let text):
						text
					case .argument(let index):
						"<foreign-type>&lt;\(argumentTypes[index].name)&gt;</foreign-type>"
					case .vector:
						"<foreign-type>&lt;vector&gt;</foreign-type>"
				}
			}
			.joined(separator: "")
	}
}

extension DEX.Unpacked.ArgumentType {
	var name: StaticString {
		switch self {
			case .boolean: "boolean"
			case .character: "character"
			case .degrees: "degrees"
			case .dialogue: "dialogue"
			case .effect: "effect"
			case .fixedPoint: "fixed-point"
			case .flag: "flag"
			case .fossil: "fossil"
			case .frames: "frames"
			case .image: "image"
			case .integer: "integer"
			case .map: "map"
			case .movement: "movement"
			case .music: "music"
			case .soundEffect: "sound effect"
			case .unknown: "unknown"
			case .vivosaur: "vivosaur"
		}
	}
}
