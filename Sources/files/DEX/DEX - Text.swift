//
//  DEX - Text.swift
//
//
//  Created by simon pellerin on 2023-07-10.
//

import Foundation
import RegexBuilder

extension DEXFile {
	init(named name: String, text inputText: Data) throws {
		self.name = String(name.dropLast(8)) // remove .dex.txt
		
		guard let text = String(bytes: inputText, encoding: .utf8) else {
			throw Datastream.ReadError.invalidUTF8(value: [UInt8](inputText), context: "")
		}
		
		script = try text
			.split(separator: "\n", omittingEmptySubsequences: false)
			.split(separator: "")
			.map {
				try $0.map(Command.init)
			}
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
	enum InvalidCommand: Error {
		case invalidCommand(command: String, fullCommand: Substring)
		case invalidNumberOfArguments(expected: Int, got: Int, command: Substring)
		case invalidArgument(argument: Substring, command: Substring)
	}
	
	init(from text: Substring) throws {
		let (command, arguments) = parse(command: text)
		
		switch command {
			case "dialogue":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .dialogue(dialogue)
			case "spawn at , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .spawn(character, unknown1, x: x, y: y, unknown2)
			case "despawn":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .despawn(character)
			case "fade out":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeOut(frameCount: frameCount)
			case "fade in":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeIn(frameCount: frameCount)
			case "unowned dialogue":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .unownedDialogue(dialogue)
			case "turn to":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .turnTo(character, angle: angle)
			case "turn1 to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turn1To(character, angle: angle, frameCount: frameCount, unknown)
			case "turn towards over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turnTowards(character, target: target, frameCount: frameCount, unknown)
			case "turn2 to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turn2To(character, angle: angle, frameCount: frameCount, unknown)
			case "turn towards over , unknowns:":
				guard arguments.count == 5 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 5, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown1 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				guard let unknown2 = Int32(arguments[4]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[4], command: text)
				}
				self = .turnTowards2(character, target: target, unknown1, frameCount: frameCount, unknown2)
			case "move to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .moveTo(character, x: x, y: y, frameCount: frameCount, unknown)
			case "move by over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .moveBy(character, relativeX: x, relativeY: y, frameCount: frameCount, unknown)
			case "delay":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .delay(frameCount: frameCount)
			case "clean1 , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let fossil = Fossil(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = UInt32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .clean1(unknown, fossil)
			case "clean2 , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let fossil = Fossil(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = UInt32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .clean2(unknown, fossil)
			case "angle camera from at distance with fov: over , unknown:":
				guard arguments.count == 5 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 5, got: arguments.count, command: text)
				}
				guard let (x, y) = position(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let distance = UInt32(arguments[1].replacing("0x", with: ""), radix: 16) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let fov = UInt32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let frameCount = frames(from: arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				guard let unknown = Int32(arguments[4]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[4], command: text)
				}
				self = .angleCamera(fov: fov, xRotation: x, yRotation: y, targetDistance: distance, frameCount: frameCount, unknown)
			case "start music":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let id = UInt32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .startMusic(id: id)
			case "fade music":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeMusic(frameCount: frameCount)
			case "play sound":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let id = UInt32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .playSound(id: id)
			case "effect on":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let effect = Effect(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let character = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .characterEffect(character, effect)
			case "clear effects on":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .clearEffects(character)
			case "movement on":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let movement = Movement(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let character = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .characterMovement(character, movement)
			case "dialogue with choice , unknown:":
				guard arguments.count == 3 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 3, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let choices = Dialogue(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown = UInt32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				self = .dialogueChoice(dialogue, unknown, choices: choices)
			case "fade out image over , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = Int32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .imageFadeOut(frameCount: frameCount, unknown)
			case "slide in image over , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let image = Image(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .imageSlideIn(image, unknown1, frameCount: frameCount, unknown2)
			case "fade in image over , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let image = Image(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .imageFadeIn(image, unknown1, frameCount: frameCount, unknown2)
			case "revive":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let vivosaur = Vivosaur(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .revive(vivosaur)
			case "start turning to follow":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .startTurning(character, target: target)
			case "stop turning":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .stopTurning(character)
			case "unknown:":
				guard arguments.count > 0 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				
				guard let type = UInt32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				
				let intArguments = try arguments
					.dropFirst()
					.map {
						if $0.contains("0x") {
							guard let value = UInt32($0.replacing("0x", with: ""), radix: 16) else {
								throw InvalidCommand.invalidArgument(argument: $0, command: text)
							}
							return value
						} else {
							guard let value = UInt32($0) else {
								throw InvalidCommand.invalidArgument(argument: $0, command: text)
							}
							return value
						}
					}
				
				self = .unknown(type: type, arguments: intArguments)
			default:
				throw InvalidCommand.invalidCommand(command: command, fullCommand: text)
		}
	}
	
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
			case .turnTo(let character, angle: let angle):
				"turn \(character) to \(degrees(angle))"
			case .turn1To(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn1 \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turnTowards(let character, target: let target, frameCount: let frameCount, let unknown):
				"turn \(character) towards \(target) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turn2To(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn2 \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turnTowards2(let character, target: let target, let unknown1, frameCount: let frameCount, let unknown2):
				"turn \(character) towards \(target) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .moveTo(let character, x: let x, y: let y, frameCount: let frameCount, let unknown):
				"move \(character) to \(position(x, y)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .moveBy(let character, relativeX: let relativeX, relativeY: let relativeY, frameCount: let frameCount, let unknown):
				"move \(character) by \(position(relativeX, relativeY)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .delay(frameCount: let frameCount):
				"delay \(frames(frameCount))"
			case .clean1(let unknown, let fossil):
				"clean1 \(fossil), unknown: <\(unknown)>"
			case .clean2(let unknown, let fossil):
				"clean2 \(fossil), unknown: <\(unknown)>"
			case .angleCamera(fov: let fov, xRotation: let xRotation, yRotation: let yRotation, targetDistance: let targetDistance, frameCount: let frameCount, let unknown):
				"angle camera from \(position(xRotation, yRotation)) at distance <\(String(targetDistance, radix: 16))> with fov: <\(fov)> over \(frames(frameCount)), unknown: <\(unknown)>"
			case .startMusic(id: let id):
				"start music <\(id)>"
			case .fadeMusic(frameCount: let frameCount):
				"fade music \(frames(frameCount))"
			case .playSound(id: let id):
				"play sound <\(id)>"
			case .characterEffect(let character, let effect):
				"effect \(effect) on \(character)"
			case .clearEffects(let character):
				"clear effects on \(character)"
			case .characterMovement(let character, let movement):
				"movement \(movement) on \(character)"
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
			case .startTurning(let character, target: let target):
				"start turning \(character) to follow \(target)"
			case .stopTurning(let character):
				"stop turning \(character)"
			case .unknown(type: let type, arguments: let arguments):
				"unknown: <\(type)> \(unknowns(arguments, hex: arguments.contains { $0 > UInt16.max }))"
		}
	}
}

fileprivate func parse(command: Substring) -> (String, [Substring]) {
	let commandRegex = try! Regex(#"(?'command'[^\n<> ]+)|<(?'argument'[\w, -]+)>"#)
	let matches = command.matches(of: commandRegex)
	
	let commandParts = matches.compactMap { $0["command"]?.substring }
	let arguments = matches.compactMap { $0["argument"]?.substring }
	
	return (
		commandParts.joined(separator: " "),
		arguments
	)
}

extension DEXFile.Command.Dialogue: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = UInt32(text) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<\(id)>"
	}
}

extension DEXFile.Command.Character: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ UInt32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<character \(id)>"
	}
}

extension DEXFile.Command.Fossil: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ UInt32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<fossil \(id)>"
	}
}

extension DEXFile.Command.Effect: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last else { return nil }
		
		switch id {
			case "haha", "4":
				self = .haha
			case "threeWhiteLines", "5":
				self = .threeWhiteLines
			case "threeRedLines", "7":
				self = .threeRedLines
			case "questionMark", "8":
				self = .questionMark
			case "thinking", "9":
				self = .thinking
			case "ellipses", "22":
				self = .ellipses
			case "lightBulb", "23":
				self = .lightBulb
			default:
				guard let type = UInt32(id) else { return nil }
				self = .unknown(type)
		}
	}
	
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
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last else { return nil }
		
		switch id {
			case "jump", "1":
				self = .jump
			case "quake", "8":
				self = .quake
			default:
				guard let type = UInt32(id) else { return nil }
				self = .unknown(type)
		}
	}
	
	var description: String {
		switch self {
			case .jump: "<movement jump>"
			case .quake: "<movement quake>"
			case .unknown(let type): "<movement \(type)>"
		}
	}
}

extension DEXFile.Command.Image: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ UInt32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<image \(id)>"
	}
}

extension DEXFile.Command.Vivosaur: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ UInt32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<vivosaur \(id)>"
	}
}

fileprivate func position(from text: Substring) -> (Int32, Int32)? {
	let coords = text.replacing("0x", with: "").split(separator: ", ")
	guard coords.count == 2,
		  let x = Int32(coords[0], radix: 16),
		  let y = Int32(coords[1], radix: 16) else { return nil }
	return (x, y)
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

fileprivate func frames(from text: Substring) -> UInt32? {
	text
		.split(separator: " ")
		.first
		.flatMap({ UInt32($0) })
}

fileprivate func frames(_ frameCount: UInt32) -> String {
	"<\(frameCount) frames>"
}

fileprivate func degrees(from text: Substring) -> Int32? {
	text
		.split(separator: " ")
		.first
		.flatMap({ Int32($0) })
}

fileprivate func degrees(_ angle: Int32) -> String {
	"<\(angle) degrees>"
}
