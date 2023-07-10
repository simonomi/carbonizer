//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-07-04.
//

import Foundation

extension DEXFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		data.seek(to: 4)
		
		let numberOfScenes = try data.read(UInt32.self)
		
		let sceneOffsetsStart = try data.read(UInt32.self)
		data.seek(to: sceneOffsetsStart)
		
		let sceneOffsets = try (0 ..< numberOfScenes) .map { _ in
			try data.read(UInt32.self)
		}
		let sceneLengths = sceneOffsets.toLengths(withEndOffset: UInt32(inputData.count))
		
		script = try sceneLengths.map {
			try createScene(from: data, length: $0)
		}
	}
}

fileprivate func createScene(from data: Datastream, length: UInt32) throws -> [DEXFile.Command] {
	let startOffset = UInt32(data.offset)
	
	let numberOfCommands = try data.read(UInt32.self)
	
	let offsetsOffset = try data.read(UInt32.self)
	data.seek(to: startOffset + offsetsOffset)
	
	let commandOffsets = try (0 ..< numberOfCommands) .map { _ in
		try data.read(UInt32.self)
	}
	
	return try commandOffsets.map {
		data.seek(to: startOffset + $0)
		return try DEXFile.Command(from: data)
	}
}

extension DEXFile.Command {
	init(from data: Datastream) throws {
		let startOffset = UInt32(data.offset)
		
		let type = try data.read(UInt32.self)
		let numberOfArguments = try data.read(UInt32.self)
		let argumentsStart = try data.read(UInt32.self)
		
		data.seek(to: startOffset + argumentsStart)
		
		switch type {
			case 1:
				self = .dialogue(try Dialogue(from: data))
			case 7:
				self = .spawn(
					try Character(from: data),
					try data.read(UInt32.self),
					x: try data.read(Int32.self),
					y: try data.read(Int32.self),
					try data.read(Int32.self)
				)
			case 14:
				self = .despawn(try Character(from: data))
			case 20:
				self = .fadeOut(frameCount: try data.read(UInt32.self))
			case 21:
				self = .fadeIn(frameCount: try data.read(UInt32.self))
			case 32:
				self = .unownedDialogue(try Dialogue(from: data))
			case 34:
				self = .faceDirection(
					try Character(from: data),
					angle: try data.read(Int32.self)
				)
			case 35:
				self = .faceDirection2(
					try Character(from: data),
					angle: try data.read(Int32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 36:
				self = .faceCharacter(
					try Character(from: data),
					target: try Character(from: data),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 37:
				self = .faceDirection3(
					try Character(from: data),
					angle: try data.read(Int32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 38:
				self = .faceCharacter2(
					try Character(from: data),
					target: try Character(from: data),
					try data.read(UInt32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 43:
				self = .move(
					try Character(from: data),
					x: try data.read(Int32.self),
					y: try data.read(Int32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 45:
				self = .moveRelative(
					try Character(from: data),
					relativeX: try data.read(Int32.self),
					relativeY: try data.read(Int32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 56:
				self = .delay(frameCount: try data.read(UInt32.self))
			case 58:
				self = .clean(
					try data.read(UInt32.self),
					try Fossil(from: data)
				)
			case 59:
				self = .clean2(
					try data.read(UInt32.self),
					try Fossil(from: data)
				)
			case 61:
				self = .moveCamera(
					fov: try data.read(UInt32.self),
					xRotation: try data.read(Int32.self),
					yRotation: try data.read(Int32.self),
					targetDistance: try data.read(UInt32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 117:
				self = .startMusic(id: try data.read(UInt32.self))
			case 124:
				self = .fadeMusic(frameCount: try data.read(UInt32.self))
			case 125:
				self = .playSound(id: try data.read(UInt32.self))
			case 129:
				self = .characterEffect(
					try Character(from: data),
					try Effect(from: data)
				)
			case 131:
				self = .clearEffects(try Character(from: data))
			case 135:
				self = .characterMovement(
					try Character(from: data),
					try Movement(from: data)
				)
			case 144:
				self = .dialogueChoice(
					try Dialogue(from: data),
					try data.read(UInt32.self),
					choices: try Dialogue(from: data)
				)
			case 154:
				self = .imageFadeOut(
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 155:
				self = .imageSlideIn(
					try Image(from: data),
					try data.read(UInt32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 157:
				self = .imageFadeIn(
					try Image(from: data),
					try data.read(UInt32.self),
					frameCount: try data.read(UInt32.self),
					try data.read(Int32.self)
				)
			case 191:
				self = .revive(try Vivosaur(from: data))
			case 200:
				self = .watch(
					try Character(from: data),
					target: try Character(from: data)
				)
			case 201:
				self = .stopWatching(try Character(from: data))
			default:
				self = .unknown(
					type: type,
					arguments: try (0 ..< numberOfArguments).map { _ in
						try data.read(UInt32.self)
					}
				)
		}
	}
	
	func write(to data: Datawriter) throws {
		switch self {
			case .dialogue(let dialogue):
				data.write(UInt32(1))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				dialogue.write(to: data)
			case .spawn(let character, let unknown1, x: let x, y: let y, let unknown2):
				data.write(UInt32(7))
				data.write(UInt32(5))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(unknown1)
				data.write(x)
				data.write(y)
				data.write(unknown2)
			case .despawn(let character):
				data.write(UInt32(14))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				character.write(to: data)
			case .fadeOut(frameCount: let frameCount):
				data.write(UInt32(20))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(frameCount)
			case .fadeIn(frameCount: let frameCount):
				data.write(UInt32(21))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(frameCount)
			case .unownedDialogue(let dialogue):
				data.write(UInt32(32))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				dialogue.write(to: data)
			case .faceDirection(let character, angle: let angle):
				data.write(UInt32(34))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(angle)
			case .faceDirection2(let character, angle: let angle, frameCount: let frameCount, let unknown):
				data.write(UInt32(35))
				data.write(UInt32(4))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(angle)
				data.write(frameCount)
				data.write(unknown)
			case .faceCharacter(let character, target: let target, frameCount: let frameCount, let unknown):
				data.write(UInt32(36))
				data.write(UInt32(4))
				data.write(UInt32(0xc))
				character.write(to: data)
				target.write(to: data)
				data.write(frameCount)
				data.write(unknown)
			case .faceDirection3(let character, angle: let angle, frameCount: let frameCount, let unknown):
				data.write(UInt32(37))
				data.write(UInt32(4))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(angle)
				data.write(frameCount)
				data.write(unknown)
			case .faceCharacter2(let character, target: let target, let unknown1, frameCount: let frameCount, let unknown2):
				data.write(UInt32(38))
				data.write(UInt32(5))
				data.write(UInt32(0xc))
				character.write(to: data)
				target.write(to: data)
				data.write(unknown1)
				data.write(frameCount)
				data.write(unknown2)
			case .move(let character, x: let x, y: let y, frameCount: let frameCount, let unknown):
				data.write(UInt32(43))
				data.write(UInt32(5))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(x)
				data.write(y)
				data.write(frameCount)
				data.write(unknown)
			case .moveRelative(let character, relativeX: let relativeX, relativeY: let relativeY, frameCount: let frameCount, let unknown):
				data.write(UInt32(45))
				data.write(UInt32(5))
				data.write(UInt32(0xc))
				character.write(to: data)
				data.write(relativeX)
				data.write(relativeY)
				data.write(frameCount)
				data.write(unknown)
			case .delay(frameCount: let frameCount):
				data.write(UInt32(56))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(frameCount)
			case .clean(let unknown, let fossil):
				data.write(UInt32(58))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				data.write(unknown)
				fossil.write(to: data)
			case .clean2(let unknown, let fossil):
				data.write(UInt32(59))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				data.write(unknown)
				fossil.write(to: data)
			case .moveCamera(fov: let fov, xRotation: let xRotation, yRotation: let yRotation, targetDistance: let targetDistance, frameCount: let frameCount, let unknown):
				data.write(UInt32(61))
				data.write(UInt32(6))
				data.write(UInt32(0xc))
				data.write(fov)
				data.write(xRotation)
				data.write(yRotation)
				data.write(targetDistance)
				data.write(frameCount)
				data.write(unknown)
			case .startMusic(id: let id):
				data.write(UInt32(117))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(id)
			case .fadeMusic(frameCount: let frameCount):
				data.write(UInt32(124))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(frameCount)
			case .playSound(id: let id):
				data.write(UInt32(125))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				data.write(id)
			case .characterEffect(let character, let effect):
				data.write(UInt32(129))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				character.write(to: data)
				effect.write(to: data)
			case .clearEffects(let character):
				data.write(UInt32(131))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				character.write(to: data)
			case .characterMovement(let character, let movement):
				data.write(UInt32(135))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				character.write(to: data)
				movement.write(to: data)
			case .dialogueChoice(let dialogue, let unknown, choices: let choices):
				data.write(UInt32(144))
				data.write(UInt32(3))
				data.write(UInt32(0xc))
				dialogue.write(to: data)
				data.write(unknown)
				choices.write(to: data)
			case .imageFadeOut(frameCount: let frameCount, let unknown):
				data.write(UInt32(154))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				data.write(frameCount)
				data.write(unknown)
			case .imageSlideIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				data.write(UInt32(155))
				data.write(UInt32(4))
				data.write(UInt32(0xc))
				image.write(to: data)
				data.write(unknown1)
				data.write(frameCount)
				data.write(unknown2)
			case .imageFadeIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				data.write(UInt32(157))
				data.write(UInt32(4))
				data.write(UInt32(0xc))
				image.write(to: data)
				data.write(unknown1)
				data.write(frameCount)
				data.write(unknown2)
			case .revive(let vivosaur):
				data.write(UInt32(191))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				vivosaur.write(to: data)
			case .watch(let character, target: let target):
				data.write(UInt32(200))
				data.write(UInt32(2))
				data.write(UInt32(0xc))
				character.write(to: data)
				target.write(to: data)
			case .stopWatching(let character):
				data.write(UInt32(201))
				data.write(UInt32(1))
				data.write(UInt32(0xc))
				character.write(to: data)
			case .unknown(type: let type, arguments: let arguments):
				data.write(type)
				data.write(UInt32(arguments.count))
				data.write(UInt32(0xc))
				arguments.forEach(data.write)
		}
	}
}

extension DEXFile.Command.Dialogue {
	init(from data: Datastream) throws {
		id = try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
	}
}

extension DEXFile.Command.Character {
	init(from data: Datastream) throws {
		id = try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
	}
}

extension DEXFile.Command.Fossil {
	init(from data: Datastream) throws {
		id = try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
	}
}

extension DEXFile.Command.Effect {
	init(from data: Datastream) throws {
		let type = try data.read(UInt32.self)
		switch type {
			case 4:
				self = .haha
			case 5:
				self = .threeWhiteLines
			case 7:
				self = .threeRedLines
			case 8:
				self = .questionMark
			case 9:
				self = .thinking
			case 22:
				self = .ellipses
			case 23:
				self = .lightBulb
			default:
				self = .unknown(type)
		}
	}
	
	func write(to data: Datawriter) {
		switch self {
			case .haha:
				data.write(UInt32(4))
			case .threeWhiteLines:
				data.write(UInt32(5))
			case .threeRedLines:
				data.write(UInt32(7))
			case .questionMark:
				data.write(UInt32(8))
			case .thinking:
				data.write(UInt32(9))
			case .ellipses:
				data.write(UInt32(22))
			case .lightBulb:
				data.write(UInt32(23))
			case .unknown(let type):
				data.write(type)
		}
	}
}

extension DEXFile.Command.Movement {
	init(from data: Datastream) throws {
		let type = try data.read(UInt32.self)
		switch type {
			case 1:
				self = .jump
			case 8:
				self = .quake
			default:
				self = .unknown(type)
		}
	}
	
	func write(to data: Datawriter) {
		switch self {
			case .jump:
				data.write(UInt32(1))
			case .quake:
				data.write(UInt32(8))
			case .unknown(let type):
				data.write(type)
		}
	}
}

extension DEXFile.Command.Image {
	init(from data: Datastream) throws {
		id = try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
	}
}

extension DEXFile.Command.Vivosaur {
	init(from data: Datastream) throws {
		id = try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
	}
}

extension Data {
	init(from dexFile: DEXFile) throws {
		let data = Datawriter()
		
		try data.write("DEX\0")
		
		data.write(UInt32(dexFile.script.count))
		
		let sceneOffsetsStart = UInt32(12)
		data.write(sceneOffsetsStart)
		
		data.seek(bytes: dexFile.script.count * 4)
		
		var sceneOffsets = [UInt32]()
		for scene in dexFile.script {
			sceneOffsets.append(UInt32(data.offset))
			
			let startOffset = UInt32(data.offset)
			
			data.write(UInt32(scene.count))
			
			let offsetsOffset = UInt32(8)
			data.write(offsetsOffset)
			
			data.seek(bytes: scene.count * 4)
			
			var commandOffsets = [UInt32]()
			for command in scene {
				commandOffsets.append(UInt32(data.offset) - startOffset)
				try command.write(to: data)
			}
			
			let endOffset = data.offset
			
			data.seek(to: startOffset + offsetsOffset)
			commandOffsets.forEach(data.write)
			
			data.seek(to: endOffset)
		}
		
		data.seek(to: sceneOffsetsStart)
		
		sceneOffsets.forEach(data.write)
		
		self = data.data
	}
}
