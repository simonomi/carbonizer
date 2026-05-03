import BinaryParser
import Foundation

enum SpriteAnimation {
	struct Packed: BinaryConvertible {
		var commands: [Command]
		var leftoverBytesIsDoubled: UInt16?
		var leftoverBytes: Data?
		
		init(_ data: inout Datastream) throws {
			commands = [Command]()
			repeat {
				commands.append(try data.read(Command.self))
			} while !commands.last!.isStop
			
			guard case .stop(let count) = commands.last! else {
				fatalError("unreachable")
			}
			
			if count > 0 {
				// kinda hacky bc i dont understand how this works yet
				leftoverBytesIsDoubled = try data.read(UInt16.self)
				
				// isDoubled == 0: count * 32 items
				// isDoubled == 1: 2 * count * 32 items
				let length = Int(leftoverBytesIsDoubled! + 1) * Int(count) * 32
				leftoverBytes = try data.read(Data.self, length: length)
			} else {
				leftoverBytesIsDoubled = nil
				leftoverBytes = nil
			}
		}
		
		func write(to data: Datawriter) {
			commands.forEach(data.write)
			
			if let leftoverBytesIsDoubled {
				data.write(leftoverBytesIsDoubled)
			}
			
			if let leftoverBytes  {
				data.write(leftoverBytes)
			}
			
			data.fourByteAlign()
		}
		
		enum Command: BinaryConvertible {
			case palette(image: UInt8, number: UInt16)
			case bitmap(image: UInt8, number: UInt16)
			case show(image: UInt8)
			case hide(image: UInt8)
			case unknown4(UInt8, UInt16)
			case position(image: UInt8, width: Int16, height: Int16)
			// nonexistant 6
			// xr 7 9 - 0 3 4 5   7 9
			//      0: 7 6 - 2 3 4   6 8
			//    7 2 - 0 2 3
			// gg 7 4 - 0 1 2   4 7
			//
			case unknown7(UInt8)
			case commit(frames: UInt8)
			case jumpToLoop(UInt8, Int16)
			case unknown10(UInt8)
			case markLoop(UInt8)
			case stop(UInt8)
			case transform(UInt8, Int16, Int16, Int16, Int16)
			// nonexistant 14
			case unknown15(UInt8, UInt16)
			
			var isStop: Bool {
				switch self {
					case .stop: true
					default: false
				}
			}
			
			struct UnknownCommand: Error, CustomStringConvertible {
				var id: UInt8
				
				var description: String {
					"unknown animation command: \(id)"
				}
			}
			
			init(_ data: inout Datastream) throws {
				let command = try data.read(UInt8.self)
				let argument = try data.read(UInt8.self)
				
				self = switch command {
					case 0: .palette(
						image: argument,
						number: try data.read(UInt16.self)
					)
					case 1: .bitmap(
						image: argument,
						number: try data.read(UInt16.self)
					)
					case 2: .show(image: argument)
					case 3: .hide(image: argument)
					case 4: .unknown4(
						argument,
						try data.read(UInt16.self)
					)
					case 5: .position(
						image: argument,
						width: try data.read(Int16.self),
						height: try data.read(Int16.self)
					)
//					case 7: .unknown7(
//						argument//,
////						try data.read(UInt16.self),
////						try data.read(UInt16.self),
////						try data.read(UInt16.self),
////						try data.read(UInt16.self),
////						try data.read(UInt16.self)
//					)
					case 8: .commit(frames: argument)
					case 9: .jumpToLoop(
						argument,
						try data.read(Int16.self)
					)
					case 10: .unknown10(argument)
					case 11: .markLoop(argument)
					case 12: .stop(argument)
					case 13: .transform(
						argument,
						try data.read(Int16.self),
						try data.read(Int16.self),
						try data.read(Int16.self),
						try data.read(Int16.self)
					)
					case 15: .unknown15(
						argument,
						try data.read(UInt16.self)
					)
					default:
						throw UnknownCommand(id: command)
				}
			}
			
			func write(to data: Datawriter) {
				switch self {
					case .palette(let image, let number):
						data.write(UInt8(0))
						data.write(image)
						data.write(number)
					case .bitmap(let image, let number):
						data.write(UInt8(1))
						data.write(image)
						data.write(number)
					case .show(let image):
						data.write(UInt8(2))
						data.write(image)
					case .hide(let image):
						data.write(UInt8(3))
						data.write(image)
					case .unknown4(let arg, let arg2):
						data.write(UInt8(4))
						data.write(arg)
						data.write(arg2)
					case .position(let image, let width, let height):
						data.write(UInt8(5))
						data.write(image)
						data.write(width)
						data.write(height)
					case .unknown7(let arg):
						data.write(UInt8(7))
						data.write(arg)
					case .commit(let frames):
						data.write(UInt8(8))
						data.write(frames)
					case .jumpToLoop(let arg, let arg2):
						data.write(UInt8(9))
						data.write(arg)
						data.write(arg2)
					case .unknown10(let arg):
						data.write(UInt8(10))
						data.write(arg)
					case .markLoop(let arg):
						data.write(UInt8(11))
						data.write(arg)
					case .stop(let arg):
						data.write(UInt8(12))
						data.write(arg)
					case .transform(let arg, let arg1, let arg2, let arg3, let arg4):
						data.write(UInt8(13))
						data.write(arg)
						data.write(arg1)
						data.write(arg2)
						data.write(arg3)
						data.write(arg4)
					case .unknown15(let arg, let arg2):
						data.write(UInt8(15))
						data.write(arg)
						data.write(arg2)
				}
			}
		}
	}
	
	struct Unpacked: Codable {
		var commands: [Command]
		var leftoverBytesIsDoubled: UInt16?
		var leftoverBytes: Data?
		
		enum Command {
			case palette(image: UInt8, number: UInt16)
			case bitmap(image: UInt8, number: UInt16)
			case show(image: UInt8)
			case hide(image: UInt8)
			case unknown4(UInt8, UInt16)
			case position(image: UInt8, width: Int16, height: Int16)
			// nonexistant 6
			// xr 7 9 - 0 3 4 5   7 9
			//      0: 7 6 - 2 3 4   6 8
			//    7 2 - 0 2 3
			// gg 7 4 - 0 1 2   4 7
			//
			case unknown7(UInt8)
			case commit(frames: UInt8)
			case jumpToLoop(UInt8, Int16)
			case unknown10(UInt8)
			case markLoop(UInt8)
			case stop(UInt8)
			case transform(UInt8, Int16, Int16, Int16, Int16)
			// nonexistant 14
			case unknown15(UInt8, UInt16)
			
			var isNotSupported: Bool {
				switch self {
					case .unknown4, .unknown7, .unknown10, .transform, .unknown15: true
					default: false
				}
			}
		}
	}
}

extension SpriteAnimation.Unpacked {
	struct UnsupportedCommand: Error, CustomStringConvertible {
		var description: String {
			"animation contains commands that are not supported yet"
		}
	}
	
	func frames(
		palettes: [SpritePalette.Unpacked?],
		bitmaps: [SpriteBitmap.Unpacked?]
	) throws -> [BMP] {
		if commands.contains(where: \.isNotSupported) {
			throw UnsupportedCommand()
		}
		
		var bmps = [BMP]()
		
		var images = [SpriteAnimation.Image]()
		
		for command in commands {
//			print("parsing", String(command))
			
			switch command {
				case .palette(let image, let number):
					images[fitting: image].palette = number
				case .bitmap(let image, let number):
					images[fitting: image].bitmap = number
				case .show(let image):
					images[fitting: image].isVisible = true
//					guard images.isNotEmpty else { continue }
//					frames.append(try drawFrame(images: images, palettes: palettes, bitmaps: bitmaps))
				case .hide(let image):
					images[fitting: image].isVisible = false
//				case .unknown4(let arg, let uInt16):
//					<#code#>
				case .position(let image, let width, let height):
					// invert x and y
					images[fitting: image].position = SpriteAnimation.Point(x: -width, y: -height)
				// unknown7
				case .commit:
					guard images.isNotEmpty else { continue }
					bmps.append(try drawFrame(images: images, palettes: palettes, bitmaps: bitmaps))
				case .jumpToLoop: () // do nothing (for now)
//				case .unknown10(let arg):
//					<#code#>
				case .markLoop: () // do nothing (for now)
				case .stop:
					return bmps
//				case .transform(let arg, let int16, let int162, let int163, let int164):
//					<#code#>
//				case .unknown15(let arg, let uInt16):
//					<#code#>
				default: todo("\(command)")
			}
			
//			print(frames)
		}
		
		fatalError("this should never be reached")
	}
}

enum DrawFrameError: Error {
	case noImages
	case missingBitmap
	case missingPalette
}

fileprivate func drawFrame(
	images: [SpriteAnimation.Image],
	palettes: [SpritePalette.Unpacked?],
	bitmaps: [SpriteBitmap.Unpacked?]
) throws -> BMP {
	guard images.isNotEmpty else {
		throw DrawFrameError.noImages
	}
	
	for image in images {
		guard let bitmap = bitmaps[safely: Int(image.bitmap)],
			  bitmap != nil
		else {
			throw DrawFrameError.missingBitmap
		}
		
		guard let palette = palettes[safely: Int(image.palette)],
			  palette != nil
		else {
			throw DrawFrameError.missingPalette
		}
	}
	
	let leastX = images
		.map(\.position.x)
		.min()!
	let leastY = images
		.map(\.position.y)
		.min()!
	let mostX = images
		.map { $0.position.x + Int16(bitmaps[Int($0.bitmap)]!.width) }
		.max()!
	let mostY = images
		.map { $0.position.y + Int16(bitmaps[Int($0.bitmap)]!.height) }
		.max()!
	
	// TODO: this is not how the width should be calculated
	let width = (mostX - leastX).magnitude
	let height = (mostY - leastY).magnitude
	
//	print("\(width) × \(height)")
//	print("bounds (\(leastX), \(leastY)) (\(mostX), \(mostY))")
	
//	offset to make the least coordinate (0,0)
	let offset = SpriteAnimation.Point(x: -leastX, y: -leastY)
//	print("offset", offset)
//	print("positions", images.map(\.position))
//	print("corners", images.map {
//		(
//			$0.position.x + Int16(bitmaps[Int($0.bitmap)].width),
//			$0.position.y + Int16(bitmaps[Int($0.bitmap)].height)
//		)
//	})
//	print("offset positions", images.map(\.position).map { $0 + offset })
//	print("offset corners", images.map {
//		(
//			($0.position + offset).x + Int16(bitmaps[Int($0.bitmap)].width),
//			($0.position + offset).y + Int16(bitmaps[Int($0.bitmap)].height)
//		)
//	})
//	print()
	
	var canvas = BMP(
		width: UInt32(width),
		height: UInt32(height),
		contents: Array(repeating: .transparent, count: Int(width) * Int(height))
	)
	
	for image in images {
//		let heightOffset = Point(x: 0, y: -Int16(bitmaps[Int(frame.bitmap)].height))
		
//		print(frame.position + offset)
//		print(frame.position + offset + heightOffset)
		
		canvas.write(
			bitmap: bitmaps[Int(image.bitmap)]!,
			with: palettes[Int(image.palette)]!,
			at: image.position + offset //+ heightOffset
		)
	}
	
	return canvas
}

// MARK: packed
extension SpriteAnimation.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> SpriteAnimation.Unpacked {
		SpriteAnimation.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SpriteAnimation.Unpacked, configuration: Configuration) {
		commands = unpacked.commands.map(Command.init)
		leftoverBytesIsDoubled = unpacked.leftoverBytesIsDoubled
		leftoverBytes = unpacked.leftoverBytes
	}
}

extension SpriteAnimation.Packed.Command {
	fileprivate init(_ unpacked: SpriteAnimation.Unpacked.Command) {
		self = switch unpacked {
			case .palette(let image, let number):
				.palette(image: image, number: number)
			case .bitmap(let image, let number):
				.bitmap(image: image, number: number)
			case .show(let image):
				.show(image: image)
			case .hide(let image):
				.hide(image: image)
			case .unknown4(let arg, let arg2):
				.unknown4(arg, arg2)
			case .position(let image, let width, let height):
				.position(image: image, width: width, height: height)
			case .unknown7(let arg):
				.unknown7(arg)
			case .commit(let frames):
				.commit(frames: frames)
			case .jumpToLoop(let arg, let arg2):
				.jumpToLoop(arg, arg2)
			case .unknown10(let arg):
				.unknown10(arg)
			case .markLoop(let arg):
				.markLoop(arg)
			case .stop(let arg):
				.stop(arg)
			case .transform(let arg, let arg2, let arg3, let arg4, let arg5):
				.transform(arg, arg2, arg3, arg4, arg5)
			case .unknown15(let arg, let arg2):
				.unknown15(arg, arg2)
		}
	}
}

// MARK: unpacked
extension SpriteAnimation.Unpacked: ProprietaryFileData {
	static let fileExtension = ".spriteAnimation.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> SpriteAnimation.Packed {
		SpriteAnimation.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: SpriteAnimation.Packed, configuration: Configuration) {
		commands = packed.commands.map(Command.init)
		leftoverBytesIsDoubled = packed.leftoverBytesIsDoubled
		leftoverBytes = packed.leftoverBytes
	}
}

extension SpriteAnimation.Unpacked.Command {
	fileprivate init(_ packed: SpriteAnimation.Packed.Command) {
		self = switch packed {
			case .palette(let image, let number):
				.palette(image: image, number: number)
			case .bitmap(let image, let number):
				.bitmap(image: image, number: number)
			case .show(let image):
				.show(image: image)
			case .hide(let image):
				.hide(image: image)
			case .unknown4(let arg, let arg2):
				.unknown4(arg, arg2)
			case .position(let image, let width, let height):
				.position(image: image, width: width, height: height)
			case .unknown7(let arg):
				.unknown7(arg)
			case .commit(let frames):
				.commit(frames: frames)
			case .jumpToLoop(let arg, let arg2):
				.jumpToLoop(arg, arg2)
			case .unknown10(let arg):
				.unknown10(arg)
			case .markLoop(let arg):
				.markLoop(arg)
			case .stop(let arg):
				.stop(arg)
			case .transform(let arg, let arg2, let arg3, let arg4, let arg5):
				.transform(arg, arg2, arg3, arg4, arg5)
			case .unknown15(let arg, let arg2):
				.unknown15(arg, arg2)
		}
	}
}

extension SpriteAnimation.Unpacked.Command: Codable {
	enum ParsingError: Error, CustomStringConvertible {
		case invalidCommand(String)
		case missingArgument(in: String)
		case invalidArgument(in: String, Substring)
		case argumentOutOfRange(Int, expected: Any.Type, in: String)
		
		var description: String {
			switch self {
				case .invalidCommand(let command):
					"invalid command: \(.red)'\(command)'\(.normal)"
				case .missingArgument(in: let command):
					"invalid command: \(.red)'\(command)'\(.normal): missing argument"
				case .invalidArgument(in: let command, let argument):
					"invalid command: \(.red)'\(command)'\(.normal): invalid argument: \(.red)'\(argument)'\(.normal)"
				case .argumentOutOfRange(let int, let expectedType, in: let command):
					"invalid command: \(.red)'\(command)'\(.normal): argument \(.red)\(int)\(.normal) out of range (expected \(.green)\(expectedType)\(.normal))"
			}
		}
	}
	
	init(from decoder: any Decoder) throws {
		try self.init(String(from: decoder))
	}
	
	func encode(to encoder: any Encoder) throws {
		try String(self).encode(to: encoder)
	}
	
	init(_ command: String) throws(ParsingError) {
		let components = command.split(separator: #/[ x]/#)
		
		func argument<Result: BinaryInteger & SendableMetatype>(
			_ index: Int
		) throws(ParsingError) -> Result {
			guard components.indices.contains(index) else {
				throw .missingArgument(in: command)
			}
			
			let argumentNumber = try Int(components[index])
				.orElseThrow(ParsingError.invalidArgument(in: command, components[index]))
			
			return try Result(exactly: argumentNumber)
				.orElseThrow(ParsingError.argumentOutOfRange(argumentNumber, expected: Result.self, in: command))
		}
		
		self = switch try components.first.orElseThrow(ParsingError.invalidCommand(command)) {
			case "palette":
				.palette(
					image: try argument(1),
					number: try argument(2)
				)
			case "bitmap":
				.bitmap(
					image: try argument(1),
					number: try argument(2)
				)
			case "show":
				.show(image: try argument(1))
			case "hide":
				.hide(image: try argument(1))
			case "unknown4":
				.unknown4(
					try argument(1),
					try argument(2)
				)
			case "position":
				.position(
					image: try argument(1),
					width: try argument(2),
					height: try argument(3)
				)
			case "unknown7":
				.unknown7(try argument(1))
			case "commit":
				.commit(frames: try argument(1))
			case "jump-to-loop":
				.jumpToLoop(
					try argument(1),
					try argument(2)
				)
			case "unknown10":
				.unknown10(try argument(1))
			case "mark-loop":
				.markLoop(try argument(1))
			case "stop":
				.stop(try argument(1))
			case "transform":
				.transform(
					try argument(1),
					try argument(2),
					try argument(3),
					try argument(4),
					try argument(5)
				)
			case "unknown15":
				.unknown15(
					try argument(1),
					try argument(2)
				)
			default: throw .invalidCommand(command)
		}
	}
}

extension String {
	init(_ command: SpriteAnimation.Unpacked.Command) {
		self = switch command {
			case .palette(let image, let number):
				"palette \(image) \(number)"
			case .bitmap(let image, let number):
				"bitmap \(image) \(number)"
			case .show(let image):
				"show \(image)"
			case .hide(let image):
				"hide \(image)"
			case .unknown4(let arg, let uInt16):
				"unknown4 \(arg) \(uInt16)"
			case .position(let image, let width, let height):
				"position \(image) \(width)x\(height)"
			case .unknown7(let arg):
				"unknown7 \(arg)"
			case .commit(let frames):
				"commit \(frames)"
			case .jumpToLoop(let arg, let number):
				"jump-to-loop \(arg) \(number)"
			case .unknown10(let arg):
				"unknown10 \(arg)"
			case .markLoop(let arg):
				"mark-loop \(arg)"
			case .stop(let arg):
				"stop \(arg)"
			case .transform(let arg, let one, let two, let three, let four):
				"transform \(arg) \(one) \(two) \(three) \(four)"
			case .unknown15(let arg, let one):
				"unknown15 \(arg) \(one)"
		}
	}
}
