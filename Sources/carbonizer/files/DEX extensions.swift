extension DEX.Binary.Scene {
	init(_ commands: [DEX.Command]) {
		numberOfCommands = UInt32(commands.count)
		
		commandOffsets = createOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: commands.map(\.size)
		)
		
		self.commands = commands.compactMap(Command.init)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Command {
	var size: UInt32 {
		guard let typeAndArguments else { return 0 }
		return 12 + UInt32(typeAndArguments.1.count * 4)
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
