import XCTest
import BinaryParser

@testable import carbonizer

func assertDescriptionsEqual<T>(_ left: T, _ right: T) {
	XCTAssertEqual(String(describing: left), String(describing: right))
}

#if compiler(>=6)
extension DEX.Command.Argument: @retroactive ExpressibleByIntegerLiteral {
	public init(integerLiteral value: IntegerLiteralType) {
		self.init(Int32(value))
	}
}
#else
extension DEX.Command.Argument: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: IntegerLiteralType) {
		self.init(Int32(value))
	}
}
#endif

let exampleCommands: [DEX.Command] = [
	.dialogue(12),
	.spawn(12, 12, position: .init(x: 12, y: 12), 12),
	.despawn(12),
	.fadeOut(12),
	.fadeIn(12),
	.unownedDialogue(12),
	.turnTo(12, 12),
	.turn1To(12, 12, 12, 12),
	.turnTowards(12, target: 12, 12, 12),
	.turn2To(12, 12, 12, 12),
	.turnTowards2(12, target: 12, 12, 12, 12),
	.moveTo(12, position: .init(x: 12, y: 12), 12, 12),
	.moveBy(12, relative: .init(x: 12, y: 12), 12, 12),
	.delay(12),
	.clean1(12, 12),
	.clean2(12, 12),
	.angleCamera(fov: 12, rotation: .init(x: 12, y: 12), targetDistance: 12, 12, 12),
	.startMusic(id: 12),
	.fadeMusic(12),
	.playSound(id: 12),
	.characterEffect(12, .init(12)),
	.clearEffects(12),
	.characterMovement(12, 12),
	.dialogueChoice(12, 12, choices: 12),
	.imageFadeOut(12, 12),
	.imageSlideIn(12, 12, 12, 12),
	.imageFadeIn(12, 12, 12, 12),
	.revive(12),
	.startTurning(12, target: 12),
	.stopTurning(12),
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
