extension DEX.Binary.Scene {
	init(_ commands: [DEX.Command]) {
		self.commands = commands
			.filter(\.isNotComment)
			.compactMap(Command.init)
		
		numberOfCommands = UInt32(self.commands.count)
		
		commandOffsets = createOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: self.commands.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Binary.Scene.Command {
	init?(_ command: DEX.Command) {
		guard let typeAndArguments = command.typeAndArguments else { return nil }
		(type, arguments) = typeAndArguments
		numberOfArguments = UInt32(arguments.count)
	}
	
	var size: UInt32 {
		12 + UInt32(arguments.count * 4)
	}
}
