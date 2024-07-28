import XCTest
import BinaryParser

@testable import carbonizer

func assertDescriptionsEqual<T>(_ left: T, _ right: T) {
	XCTAssertEqual(String(describing: left), String(describing: right))
}

let exampleCommands: [DEX.Command] = [
	.dialogue(DEX.Command.Dialogue(1)),
	.spawn(DEX.Command.Character(1), 1, x: 1, y: 1, 1),
	.despawn(DEX.Command.Character(1)),
	.fadeOut(frameCount: 1),
	.fadeIn(frameCount: 1),
	.unownedDialogue(DEX.Command.Dialogue(1)),
	.turnTo(DEX.Command.Character(1), angle: 1),
	.turn1To(DEX.Command.Character(1), angle: 1, frameCount: 1, 1),
	.turnTowards(DEX.Command.Character(1), target: DEX.Command.Character(1), frameCount: 1, 1),
	.turn2To(DEX.Command.Character(1), angle: 1, frameCount: 1, 1),
	.turnTowards2(DEX.Command.Character(1), target: DEX.Command.Character(1), 1, frameCount: 1, 1),
	.moveTo(DEX.Command.Character(1), x: 1, y: 1, frameCount: 1, 1),
	.moveBy(DEX.Command.Character(1), relativeX: 1, relativeY: 1, frameCount: 1, 1),
	.delay(frameCount: 1),
	.clean1(1, DEX.Command.Fossil(1)),
	.clean2(1, DEX.Command.Fossil(1)),
	.angleCamera(fov: 1, xRotation: 1, yRotation: 1, targetDistance: 1, frameCount: 1, 1),
	.startMusic(id: 1),
	.fadeMusic(frameCount: 1),
	.playSound(id: 1),
	.characterEffect(DEX.Command.Character(1), DEX.Command.Effect.ellipses),
	.clearEffects(DEX.Command.Character(1)),
	.characterMovement(DEX.Command.Character(1), DEX.Command.Movement(1)),
	.dialogueChoice(DEX.Command.Dialogue(1), 1, choices: DEX.Command.Dialogue(1)),
	.imageFadeOut(frameCount: 1, 1),
	.imageSlideIn(DEX.Command.Image(1), 1, frameCount: 1, 1),
	.imageFadeIn(DEX.Command.Image(1), 1, frameCount: 1, 1),
	.revive(DEX.Command.Vivosaur(1)),
	.startTurning(DEX.Command.Character(1), target: DEX.Command.Character(1)),
	.stopTurning(DEX.Command.Character(1)),
	.unknown(type: 500, arguments: []),
	.unknown(type: 500, arguments: [1]),
	.unknown(type: 500, arguments: [1, 2, 3]),
	// dont test comments because they shouldnt round trip
]

let dexsToTest = [
	DEX(commands: []),
	DEX(commands: [exampleCommands]),
	DEX(
		commands: [
			Array(exampleCommands[..<10]),
			Array(exampleCommands[10..<20]),
			Array(exampleCommands[20...])
		]
	)
]

func roundTrip<T: ProprietaryFileData>(unpacked: T) throws {
	let packed = unpacked.packed()
	let cycled = packed.unpacked()
	
	assertDescriptionsEqual(unpacked, cycled)
	
	let unpackedBytes = Datawriter()
	unpackedBytes.write(unpacked)
	
	let packedBytes = Datawriter()
	packedBytes.write(packed)
	
	let cycledBytes = Datawriter()
	cycledBytes.write(cycled)
	
	XCTAssertEqual(unpackedBytes.bytes, cycledBytes.bytes)
	
	let rereadUnpacked = try unpackedBytes.intoDatastream().read(T.self)
	let rereadPacked = try packedBytes.intoDatastream().read(T.Packed.self)
	let rereadCycled = try cycledBytes.intoDatastream().read(T.self)
	
	assertDescriptionsEqual(unpacked, rereadUnpacked)
	assertDescriptionsEqual(packed, rereadPacked)
	assertDescriptionsEqual(cycled, rereadCycled)
}

class DEXTests: XCTestCase {
	func testRoundTrips() throws {
		for (index, dex) in dexsToTest.enumerated() {
			try XCTContext.runActivity(named: "Testing dexsToTest[\(index)]") { _ in
				try roundTrip(unpacked: dex)
			}
		}
	}
}
