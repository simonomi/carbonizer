import Testing

@testable import Carbonizer

@Test(arguments: [DEX.Unpacked.ff1Commands, DEX.Unpacked.ffcCommands])
func knownCommandsAreValid(commandList: [UInt32: DEX.Unpacked.CommandDefinition]) throws {
	var allCommandsWithoutArguments = Set<[String]>()
	
	for command in commandList.values {
		guard !allCommandsWithoutArguments.contains(command.textWithoutArguments) else {
			try Issue.failure("\(.red)duplicate command text for \(command.textWithoutArguments) >:(\(.normal)")
		}
		allCommandsWithoutArguments.insert(command.textWithoutArguments)
	}
}

@Test
func checkKnownRequirements() throws {
	var allRequirementsWithoutArguments = Set<[String]>()
	
	for requirement in DEP.Unpacked.knownRequirements.values {
		guard !allRequirementsWithoutArguments.contains(requirement.textWithoutArguments) else {
			try Issue.failure("\(.red)duplicate command text for \(requirement.textWithoutArguments) >:(\(.normal)")
		}
		allRequirementsWithoutArguments.insert(requirement.textWithoutArguments)
	}
}
