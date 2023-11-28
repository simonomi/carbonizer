//
//  DEX extensions.swift
//
//
//  Created by simon pellerin on 2023-11-27.
//

extension DEX.Binary.Scene {
	init(_ commands: [DEX.Command]) {
		numberOfCommands = UInt32(commands.count)
		
		commandOffsets = createOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: commands.map(\.size)
		)
		
		self.commands = commands.map(Command.init)
	}
}

extension DEX.Command {
	var size: UInt32 {
		4 + UInt32(arguments.count * 4)
	}
}

extension DEX.Binary.Scene.Command {
	init(_ command: DEX.Command) {
		type = command.type
		numberOfArguments = UInt32(command.arguments.count)
		arguments = command.arguments
	}
}
