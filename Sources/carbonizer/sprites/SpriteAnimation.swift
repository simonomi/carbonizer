import BinaryParser

enum SpriteError: Error {
	case malformedPalette(index: UInt16)
}

struct SpriteAnimation: BinaryConvertible {
	var commands: [Command]
	
	init(_ data: Datastream) throws {
		commands = [Command]()
		repeat {
			commands.append(try data.read(Command.self))
		} while !commands.last!.shouldStop
	}
	
	func write(to data: Datawriter) {
		commands.forEach(data.write)
		// TODO: pad to multiple of 4
	}
	
	enum Command: BinaryConvertible, Equatable, CustomStringConvertible {
		case palette(image: UInt8, number: UInt16)
		case bitmap(image: UInt8, number: UInt16)
		case show(image: UInt8)
		case hide(image: UInt8)
		case four(arg: UInt8, UInt16)
		case position(image: UInt8, width: Int16, height: Int16)
		// nonexistant 6
		// xr 7 9 - 0 3 4 5   7 9
		//      0: 7 6 - 2 3 4   6 8
		//    7 2 - 0 2 3
		// gg 7 4 - 0 1 2   4 7
		//
//		case seven(arg: UInt8, UInt16, UInt16, UInt16, UInt16, UInt16)
		case commit(frames: UInt8)
		case jumpToLoop(arg: UInt8, Int16)
		case ten(arg: UInt8)
		case markLoop(arg: UInt8)
		case quit(arg: UInt8) // 0
		case transform(arg: UInt8, Int16, Int16, Int16, Int16)
		// nonexistant 14
		case fifteen(arg: UInt8, UInt16)
		case unknown(command: UInt8, argument: UInt8)
		
		var isUnknown: Bool {
			switch self {
				case .unknown: true
				default: false
			}
		}
		
		var isQuit: Bool {
			switch self {
				case .quit: true
				default: false
			}
		}
		
		var shouldStop: Bool {
			isUnknown || isQuit
		}
		
		var isMalformed: Bool {
			switch self {
				case .palette(_, let number): number > 9
				case .bitmap(_, let number): number > 9
				case .unknown(let command, _): command != 7
				default: false
			}
		}
		
		init(_ data: Datastream) throws {
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
				case 4: .four(
					arg: argument,
					try data.read(UInt16.self)
				)
				case 5: .position(
					image: argument,
					width: try data.read(Int16.self),
					height: try data.read(Int16.self)
				)
//				case 7: .seven(
//					arg: argument,
//					try data.read(UInt16.self),
//					try data.read(UInt16.self),
//					try data.read(UInt16.self),
//					try data.read(UInt16.self),
//					try data.read(UInt16.self)
//				)
				case 8: .commit(frames: argument)
				case 9: .jumpToLoop(
					arg: argument,
					try data.read(Int16.self)
				)
				case 10: .ten(arg: argument)
				case 11: .markLoop(arg: argument)
				case 12: .quit(arg: argument)
				case 13: .transform(
					arg: argument,
					try data.read(Int16.self),
					try data.read(Int16.self),
					try data.read(Int16.self),
					try data.read(Int16.self)
				)
				case 15: .fifteen(
					arg: argument,
					try data.read(UInt16.self)
				)
				default: .unknown(
					command: command,
					argument: argument
				)
			}
		}
		
		func write(to data: Datawriter) {
			todo()
		}
		
		var description: String {
			switch self {
				case .palette(let image, let number):
					"\(.magenta)palette \(image) \(number)\(.normal)"
				case .bitmap(let image, let number):
					"\(.green)bitmap \(image) \(number)\(.normal)"
				case .show(let image):
					"\(.yellow)show \(image)\(.normal)"
				case .hide(let image):
					"\(.blue)hide \(image)\(.normal)"
				case .four(let arg, let uInt16):
					"four \(arg) \(uInt16)"
				case .position(let image, let width, let height):
					"\(.cyan)position \(image) \(width)x\(height)\(.normal)"
//				case .seven(let arg, let one, let two, let three, let four, _):
//					"seven \(arg) \(one) \(two) \(three) \(four)"
				case .commit(let frames):
					"\(.red)commit \(frames)\(.normal)"
				case .jumpToLoop(let arg, let number):
					"\(.brightRed)jump to loop \(arg) \(number)\(.normal)"
				case .ten(let arg):
					"ten \(arg)"
				case .markLoop(let arg):
					"\(.brightRed)mark loop \(arg)\(.normal)"
				case .quit(let arg):
					"\(.red)quit \(arg)\(.normal)"
				case .transform(let arg, let one, let two, let three, let four):
					"\(.brightBlue)transform \(arg) \(one) \(two) \(three) \(four)\(.normal)"
				case .fifteen(let arg, let one):
					"fifteen \(arg) \(one)"
				case .unknown(let command, let argument):
					"unknown \(command) \(argument)"
			}
		}
	}
	
	func frames(palettes: [SpritePalette?], bitmaps: [SpriteBitmap]) throws -> [Bitmap] {
		// cant parse 7s
		if commands.contains(where: \.isUnknown) { return [] }
		
		func dontWantToParse(_ command: Command) -> Bool {
			switch command {
				case .four, .ten, .transform, .fifteen, .unknown: true
				default: false
			}
		}
		
		if commands.contains(where: dontWantToParse) { return [] }
		
		var frames = [Bitmap]()
		
		var images = [Image]()
		
		for command in commands {
//			print("parsing", command)
			switch command {
				case .palette(let image, let number):
					images[fitting: image].palette = number
				case .bitmap(let image, let number):
					images[fitting: image].bitmap = number
				case .show(let image):
					images[fitting: image].visible = true
//					guard images.isNotEmpty else { continue }
//					frames.append(try drawFrame(images: images, palettes: palettes, bitmaps: bitmaps))
				case .hide(let image):
					images[fitting: image].visible = false
//				case .four(let arg, let uInt16):
//					<#code#>
				case .position(let image, let width, let height):
					// invert x and y
					images[fitting: image].position = Point(x: -width, y: -height)
				// seven
				case .commit:
					guard images.isNotEmpty else { continue }
					frames.append(try drawFrame(images: images, palettes: palettes, bitmaps: bitmaps))
				case .jumpToLoop: () // do nothing (for now)
//				case .ten(let arg):
//					<#code#>
				case .markLoop: () // do nothing (for now)
				case .quit:
					return frames
//				case .transform(let arg, let int16, let int162, let int163, let int164):
//					<#code#>
//				case .fifteen(let arg, let uInt16):
//					<#code#>
				case .unknown: fatalError("unreachable")
				default: todo("\(command)")
			}
//			print(images)
		}
		
		fatalError("this should never be reached")
	}
	
	fileprivate func drawFrame(
		images: [Image],
		palettes: [SpritePalette?],
		bitmaps: [SpriteBitmap]
	) throws -> Bitmap {
		let leastX = images
			.map(\.position.x)
			.map(Int32.init)
			.min()!
		let leastY = images
			.map(\.position.y)
			.map(Int32.init)
			.min()!
		let mostX = images
			.map { Int32($0.position.x) + bitmaps[Int($0.bitmap)].width }
			.max()!
		let mostY = images
			.map { Int32($0.position.y) + bitmaps[Int($0.bitmap)].height }
			.max()!
		
		let width = (mostX - leastX).magnitude
		let height = (mostY - leastY).magnitude
		
//		print("\(width) × \(height)")
//		print("bounds (\(leastX), \(leastY)) (\(mostX), \(mostY))")
		
		// offset to make the least coordinate (0,0)
		let offset = Point(x: Int16(-leastX), y: Int16(-leastY))
//		print("offset", offset)
//		print("positions", images.map(\.position))
//		print("corners", images.map {
//			(
//				$0.position.x + Int16(bitmaps[Int($0.bitmap)].width),
//				$0.position.y + Int16(bitmaps[Int($0.bitmap)].height)
//			)
//		})
//		print("offset positions", images.map(\.position).map { $0 + offset })
//		print("offset corners", images.map {
//			(
//				($0.position + offset).x + Int16(bitmaps[Int($0.bitmap)].width),
//				($0.position + offset).y + Int16(bitmaps[Int($0.bitmap)].height)
//			)
//		})
//		print()
		
		var canvas = Bitmap(
			width: Int32(width),
			height: Int32(height),
			contents: Array(repeating: .transparent, count: Int(width) * Int(height))
		)
		
		for image in images {
			assert(bitmaps.indices.contains(Int(image.bitmap)), "bitmap index out of bounds: \(image.bitmap), expected \(bitmaps.indices)")
			assert(palettes.indices.contains(Int(image.palette)), "palette index out of bounds: \(image.palette), expected \(palettes.indices)")
			
			if palettes[Int(image.palette)] == nil {
				throw SpriteError.malformedPalette(index: image.palette)
			}
			
//			let heightOffset = Point(x: 0, y: -Int16(bitmaps[Int(image.bitmap)].height))
			
//			print(image.position + offset)
//			print(image.position + offset + heightOffset)
			
			bitmaps[Int(image.bitmap)].write(
				to: &canvas,
				with: palettes[Int(image.palette)]!,
				at: image.position + offset //+ heightOffset
			)
		}
		
		return canvas
	}
}

struct Point<T: BinaryInteger & Sendable>: AdditiveArithmetic, CustomStringConvertible {
	var x: T
	var y: T
	
	var description: String {
		"(\(x), \(y))"
	}
	
	static func + (lhs: Point<T>, rhs: Point<T>) -> Point<T> {
		Point(
			x: lhs.x + rhs.x,
			y: lhs.y + rhs.y
		)
	}
	
	static func - (lhs: Point<T>, rhs: Point<T>) -> Point<T> {
		Point(
			x: lhs.x - rhs.x,
			y: lhs.y - rhs.y
		)
	}
	
	static var zero: Self { Self(x: 0, y: 0) }
}

fileprivate struct Image: CustomStringConvertible {
	var visible: Bool = false
	var palette: UInt16 = 0
	var bitmap: UInt16 = 0
	var position: Point<Int16> = .zero
//	var transform: (Int, Int, Int, Int)
	
	var description: String {
		"[\(visible ? "x" : " ")] \(palette) \(bitmap) at \(position)"
	}
}

extension [Image] {
	fileprivate subscript(fitting index: UInt8) -> Image {
		get {
			if indices.contains(Int(index)) {
				self[Int(index)]
			} else {
				Image()
			}
		}
		set {
			if indices.contains(Int(index)) {
				self[Int(index)] = newValue
			} else {
				for _ in 0...(Int(index) - count) {
					append(Image())
					self[Int(index)] = newValue
				}
			}
		}
	}
}
