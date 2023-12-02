//
//  DEX.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser
import Foundation

struct DEX: Codable {
	var commands: [[Command]]
	
	struct Command: Codable {
		var type: UInt32
		var arguments: [UInt32]
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DEX"
		var numberOfScenes: UInt32
		var sceneOffsetsStart: UInt32 = 0xC
		@Offset(givenBy: \Self.sceneOffsetsStart)
		@Count(givenBy: \Self.numberOfScenes)
		var sceneOffsets: [UInt32]
		@Offsets(givenBy: \Self.sceneOffsets)
		var script: [Scene]
		
		@BinaryConvertible
		struct Scene {
			var numberOfCommands: UInt32
			var offsetsOffset: UInt32 = 0x8
			@Offset(givenBy: \Self.offsetsOffset)
			@Count(givenBy: \Self.numberOfCommands)
			var commandOffsets: [UInt32]
			@Offsets(givenBy: \Self.commandOffsets)
			var commands: [Command]
			
			@BinaryConvertible
			struct Command {
				var type: UInt32
				var numberOfArguments: UInt32
				var argumentsStart: UInt32 = 0xC
				@Offset(givenBy: \Self.argumentsStart)
				@Count(givenBy: \Self.numberOfArguments)
				var arguments: [UInt32]
			}
		}
	}
}

// MARK: packed
extension DEX: FileData {
	init(packed: Binary) {
		commands = packed.script
			.map(\.commands)
			.recursiveMap(Command.init)
	}
}

extension DEX.Command {
	init(_ commandBinary: DEX.Binary.Scene.Command) {
		type = commandBinary.type
		arguments = commandBinary.arguments
	}
}

extension DEX.Binary: InitFrom {
	init(_ dex: DEX) {
		numberOfScenes = UInt32(dex.commands.count)
		
//		sceneOffsetsStart = dex.commands.isEmpty ? 0 : 8
		
		sceneOffsets = createOffsets(
			start: sceneOffsetsStart + numberOfScenes * 4,
			sizes: dex.commands.map { $0.size() }
		)
		
		script = dex.commands.map(Scene.init)
	}
}

extension [DEX.Command] {
	func size() -> UInt32 {
		map(\.size).sum()
	}
}
