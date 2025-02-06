extension DEX.Binary.Block {
	init(_ commands: [DEX.Command]) {
		self.commands = commands.compactMap(Command.init)
		
		numberOfCommands = UInt32(self.commands.count)
		
		commandOffsets = makeOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: self.commands.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Binary.Block.Command {
	init?(_ command: DEX.Command) {
		guard let typeAndArguments = command.typeAndArguments else { return nil }
		(type, arguments) = typeAndArguments
		numberOfArguments = UInt32(arguments.count)
	}
	
	var size: UInt32 {
		12 + UInt32(arguments.count * 4)
	}
}
