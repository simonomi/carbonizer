extension DEX.Binary.Scene {
	init(_ commands: [DEX.Command]) {
		numberOfCommands = UInt32(commands.count)
		
		commandOffsets = createOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: commands.map(\.size)
		)
		
		self.commands = commands.map(Command.init)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Command {
	var size: UInt32 {
		12 + UInt32(arguments.count * 4)
	}
}

extension DEX.Binary.Scene.Command {
	init(_ command: DEX.Command) {
		type = command.type
		numberOfArguments = UInt32(command.arguments.count)
		arguments = command.arguments
	}
	
	var size: UInt32 {
		12 + UInt32(arguments.count * 4)
	}
}
