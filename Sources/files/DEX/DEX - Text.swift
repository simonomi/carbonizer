//
//  DEX - TXT.swift
//
//
//  Created by simon pellerin on 2023-07-10.
//

import Foundation

extension DEXFile {
	init(named name: String, text: Data) throws {
		self.name = String(name.dropLast(8)) // remove .dex.txt
//		script =
		fatalError()
	}
	
	func textData() throws -> Data {
		let text = script
			.map {
				$0
					.map { $0.asText() }
					.joined(separator: "\n")
			}
			.joined(separator: "\n\n")
		
		guard let data = text.data(using: .utf8) else {
			throw Datawriter.WriteError.invalidUTF8(value: text, context: "")
		}
		return data
	}
}


extension DEXFile.Command {
	func asText() -> String {
		switch self {
			case .dialogue(let dialogue):
				"dialogue \(dialogue)"
			case .spawn(let character, let unknown1, x: let x, y: let y, let unknown2):
				"spawn \(character) at \(position(x, y)), unknowns: \(unknowns(unknown1, unknown2))"
			case .despawn(let character):
				"despawn \(character)"
			case .fadeOut(frameCount: let frameCount):
				"fade out \(frames(frameCount))"
			case .fadeIn(frameCount: let frameCount):
				"fade in \(frames(frameCount))"
			case .unownedDialogue(let dialogue):
				"unowned dialogue \(dialogue)"
			case .faceDirection(let character, angle: let angle):
				"turn \(character) to \(degrees(angle))"
			case .faceDirection2(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .faceCharacter(let character, target: let target, frameCount: let frameCount, let unknown):
				"turn \(character) to \(target) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .faceDirection3(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .faceCharacter2(let character, target: let target, let unknown1, frameCount: let frameCount, let unknown2):
				"turn \(character) to \(target) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .move(let character, x: let x, y: let y, frameCount: let frameCount, let unknown):
				"move \(character) to \(position(x, y)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .moveRelative(let character, relativeX: let relativeX, relativeY: let relativeY, frameCount: let frameCount, let unknown):
				"move \(character) by \(position(relativeX, relativeY)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .delay(frameCount: let frameCount):
				"delay \(frames(frameCount))"
			case .clean(let unknown, let fossil):
				"clean \(fossil), unknown: <\(unknown)>"
			case .clean2(let unknown, let fossil):
				"clean \(fossil), unknown: <\(unknown)>"
			case .angleCamera(fov: let fov, xRotation: let xRotation, yRotation: let yRotation, targetDistance: let targetDistance, frameCount: let frameCount, let unknown):
				"angle camera from \(position(xRotation, yRotation)) at distance <\(targetDistance)> with fov: <\(fov)> over \(frames(frameCount)), unknown: <\(unknown)>"
			case .startMusic(id: let id):
				"start music <\(id)>"
			case .fadeMusic(frameCount: let frameCount):
				"fade music \(frames(frameCount))"
			case .playSound(id: let id):
				"play sound <\(id)>"
			case .characterEffect(let character, let effect):
				"play \(effect) on \(character)"
			case .clearEffects(let character):
				"clear effects on \(character)"
			case .characterMovement(let character, let movement):
				"play \(movement) on \(character)"
			case .dialogueChoice(let dialogue, let unknown, choices: let choices):
				"dialogue \(dialogue) with choice \(choices), unknown: <\(unknown)>"
			case .imageFadeOut(frameCount: let frameCount, let unknown):
				"fade out image over \(frames(frameCount)), unknown: <\(unknown)>"
			case .imageSlideIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				"slide in image \(image) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .imageFadeIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				"fade in image \(image) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .revive(let vivosaur):
				"revive \(vivosaur)"
			case .watch(let character, target: let target):
				"start turning \(character) to follow \(target)"
			case .stopWatching(let character):
				"stop turning \(character)"
			case .unknown(type: let type, arguments: let arguments):
				"unknown: <\(type)> \(unknowns(arguments, hex: arguments.contains { $0 > UInt16.max }))"
		}
	}
}

extension DEXFile.Command.Dialogue: CustomStringConvertible {
	var description: String {
		"<\(id)>"
	}
}

extension DEXFile.Command.Character: CustomStringConvertible {
	var description: String {
		"<character \(id)>"
	}
}

extension DEXFile.Command.Fossil: CustomStringConvertible {
	var description: String {
		"<fossil \(id)>"
	}
}

extension DEXFile.Command.Vivosaur: CustomStringConvertible {
	var description: String {
		"<vivosaur \(id)>"
	}
}

extension DEXFile.Command.Effect: CustomStringConvertible {
	var description: String {
		switch self {
			case .haha: "<effect haha>"
			case .threeWhiteLines: "<effect threeWhiteLines>"
			case .threeRedLines: "<effect threeRedLines>"
			case .questionMark: "<effect questionMark>"
			case .thinking: "<effect thinking>"
			case .ellipses: "<effect ellipses>"
			case .lightBulb: "<effect lightBulb>"
			case .unknown(let type): "<effect \(type)>"
		}
	}
}

extension DEXFile.Command.Movement: CustomStringConvertible {
	var description: String {
		switch self {
			case .jump: "<movement jump>"
			case .quake: "<movement quake>"
			case .unknown(let type): "<movement \(type)>"
		}
	}
}

fileprivate func position(_ x: Int32, _ y: Int32) -> String {
	"<\(hex(x)), \(hex(y))>"
}

fileprivate func hex<T: BinaryInteger & SignedNumeric>(_ value: T) -> String {
	if value < 0 {
		"-0x\(String(-value, radix: 16))"
	} else {
		"0x\(String(value, radix: 16))"
	}
}

fileprivate func unknowns(_ unknowns: Int32...) -> String {
	unknowns.map { "<\($0)>" }.joined(separator: " ")
}

fileprivate func unknowns(_ unknowns: [UInt32], hex isHex: Bool = false) -> String {
	if isHex {
		unknowns.map { "<0x\(String($0, radix: 16))>" }.joined(separator: " ")
	} else {
		unknowns.map { "<\($0)>" }.joined(separator: " ")
	}
}

fileprivate func frames(_ frameCount: UInt32) -> String {
	"<\(frameCount) frames>"
}

fileprivate func degrees(_ angle: Int32) -> String {
	"<\(angle) degrees>"
}
