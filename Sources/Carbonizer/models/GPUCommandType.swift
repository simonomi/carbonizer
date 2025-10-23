enum GPUCommandType: UInt8, Equatable {
	case noop = 0x00
	case matrixMode = 0x10
	case matrixPush = 0x11
	case matrixPop = 0x12
	case matrixStore = 0x13
	case matrixRestore = 0x14
	case matrixIdentity = 0x15
	case matrixLoad4x4 = 0x16
	case matrixLoad4x3 = 0x17
	case matrixMultiply4x4 = 0x18
	case matrixMultiply4x3 = 0x19
	case matrixMultiply3x3 = 0x1A
	case matrixScale = 0x1B
	case matrixTranslate = 0x1C
	case color = 0x20
	case normal = 0x21
	case textureCoordinate = 0x22
	case vertex16 = 0x23
	case vertex10 = 0x24
	case vertexXY = 0x25
	case vertexXZ = 0x26
	case vertexYZ = 0x27
	case vertexDiff = 0x28
	case polygonAttributes = 0x29
	case textureImageParameter = 0x2A
	case texturePaletteBase = 0x2B
	case materialColor0 = 0x30
	case materialColor1 = 0x31
	case lightVector = 0x32
	case lightColor = 0x33
	case shininess = 0x34
	case vertexBegin = 0x40
	case vertexEnd = 0x41
	
	// case swapBuffers = 0x50
	case setViewport = 0x60
	case testBox = 0x70
	case testPosition = 0x71
	case testVector = 0x72
	
	case unknown50 = 0x50 // in the original, swap buffers, but not here
	case unknown51 = 0x51
	case commandsStart = 0x52
	case unknown53 = 0x53
	case commandsEnd = 0xFF // always followed by 0F 7F ?
	case commandsEnd1 = 0x0F
	case commandsEnd2 = 0x7F
	
	/// number of 32-bit arguments
	var argumentCount: Int? {
		switch self {
			case .noop, .matrixPush, .matrixIdentity, .vertexEnd: 0
			case .matrixMode, .matrixPop, .matrixStore, .matrixRestore, .color, .normal, .textureCoordinate, .vertex10, .vertexXY, .vertexXZ, .vertexYZ, .vertexDiff, .polygonAttributes, .textureImageParameter, .texturePaletteBase, .materialColor0, .materialColor1, .lightVector, .lightColor, .vertexBegin, .setViewport, .testVector: 1
			case .vertex16, .testPosition: 2
			case .matrixScale, .matrixTranslate, .testBox: 3
			case .matrixMultiply3x3: 9
			case .matrixLoad4x3, .matrixMultiply4x3: 12
			case .matrixLoad4x4, .matrixMultiply4x4: 16
			case .shininess: 32
			case .unknown50, .unknown51, .commandsStart, .unknown53, .commandsEnd, .commandsEnd1, .commandsEnd2: nil
		}
	}
}
