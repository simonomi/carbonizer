//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-07-04.
//

import Foundation

struct DEXFile {
	var name: String
	
	var script: [[Command]]
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".dex.txt")
			try textData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
	
	enum Command: Codable {
		case dialogue(Dialogue)
		case spawn(Character, Int32, x: Int32, y: Int32, Int32)
		case despawn(Character)
		case fadeOut(frameCount: UInt32)
		case fadeIn(frameCount: UInt32)
		case unownedDialogue(Dialogue)
		case turnTo(Character, angle: Int32)
		case turn1To(Character, angle: Int32, frameCount: UInt32, Int32)
		case turnTowards(Character, target: Character, frameCount: UInt32, Int32)
		case turn2To(Character, angle: Int32, frameCount: UInt32, Int32)
		case turnTowards2(Character, target: Character, Int32, frameCount: UInt32, Int32)
		case moveTo(Character, x: Int32, y: Int32, frameCount: UInt32, Int32)
		case moveBy(Character, relativeX: Int32, relativeY: Int32, frameCount: UInt32, Int32)
		case delay(frameCount: UInt32)
		case clean1(UInt32, Fossil)
		case clean2(UInt32, Fossil)
		case angleCamera(fov: UInt32, xRotation: Int32, yRotation: Int32, targetDistance: UInt32, frameCount: UInt32, Int32)
		case startMusic(id: UInt32)
		case fadeMusic(frameCount: UInt32)
		case playSound(id: UInt32)
		case characterEffect(Character, Effect)
		case clearEffects(Character)
		case characterMovement(Character, Movement)
		case dialogueChoice(Dialogue, UInt32, choices: Dialogue)
		case imageFadeOut(frameCount: UInt32, Int32)
		case imageSlideIn(Image, Int32, frameCount: UInt32, Int32)
		case imageFadeIn(Image, Int32, frameCount: UInt32, Int32)
		case revive(Vivosaur)
		case startTurning(Character, target: Character)
		case stopTurning(Character)
		
		case unknown(type: UInt32, arguments: [UInt32])
		
		struct Dialogue: Codable {
			var id: UInt32
		}
		
		struct Character: Codable {
			var id: UInt32
		}
		
		struct Fossil: Codable {
			var id: UInt32
		}
		
		enum Effect: Codable {
			case haha
			case threeWhiteLines
			case threeRedLines
			case questionMark
			case thinking
			case ellipses
			case lightBulb
			case unknown(UInt32)
		}
		
		enum Movement: Codable {
			case jump
			case quake
			case unknown(UInt32)
		}
		
		struct Image: Codable {
			var id: UInt32
		}
		
		struct Vivosaur: Codable {
			var id: UInt32
		}
	}
}
