import BinaryParser

//func mm3Finder(_ file: inout File, _ parent: inout Folder) throws {
////	if file.name != "cha01a_01" { return }
//	
//	if let mar = file.data as? MAR {
//		for mm3 in mar.files.compactMap({ $0.content as? MM3 }) {
////			print(file.name)
////			print("mm3", mm3.entry1, mm3.entry2, mm3.entry3)
//			let arc = parent.contents.first { $0.name == mm3.model.tableName }! as! File
//			
////			let animationData = ((arc.data as! MAR).files[Int(mm3.entry2.index)].content as! Datastream).bytes
////			let animation = Datastream(animationData)
//			
////			animation.jump(bytes: 0x10)
////			if try! animation.read(UInt32.self) != 0 {
////				print(file.name)
////			}
//			
////			animation.jump(bytes: 0x20)
////			if try! animation.read(UInt32.self) != 0 {
////				print(file.name)
////			}
//			
////			exit(0)
//			
//			let modelData = ((arc.data as! MAR).files[Int(mm3.model.index)].content as! Datastream).bytes
//			let model = Datastream(modelData)
//			
//			let _modelStart = model.placeMarker()
//			
//			model.jump(bytes: 0x08)
//			
//			let _commandsLength = try! model.read(UInt32.self)
//			let _boneTableLength = try! model.read(UInt32.self)
//			let _modelNamesLength = try! model.read(UInt32.self)
//			
//			let fourteen = try! model.read(UInt32.self)
//			guard fourteen == 3 else { continue }
//			
//			let eighteen = try! model.read(UInt32.self)
//			guard eighteen == 0x100 else { continue }
//			
//			let oneC = try! model.read(UInt32.self)
//			guard oneC == 0x3 else { continue }
//
//			let twenty = try! model.read(UInt32.self)
//			guard twenty == 0x3C else { continue }
//			
//			let _twentyFour = try! model.read(UInt32.self)
//			
////			guard file.name.starts(with: "cha01") else { continue }
//			print(file.name, mm3.model.index)
//			
////			model.jump(to: modelStart + 0x28)
//			
//			var mtxRestores = [UInt32]()
//			
//			reader: while true {
//				let commands = try (0..<4).map { _ in try model.read(UInt8.self) }.map(Int.init)
//				
//				for command in commands {
//					if command == 0xFF { break reader }
//					
//					if [0x50, 0x51].contains(command) {
//						print("UNKNOWN", "0x" + String(command, radix: 16))
//						let argumentsLength = try model.read(UInt32.self)
//						model.jump(bytes: argumentsLength)
//						break
//					}
//					
//					if command == 0x52 {
//						print("GPU command start")
//						model.jump(bytes: 4)
//						break
//					}
//					
//					print(commandNames[command]!, terminator: " ")
//					
//					if command == 0x10 { // MTX_MODE
//						let argument = try model.read(UInt32.self)
//						let mode = switch argument {
//								case 0: "Projection Matrix"
//								case 1: "Position Matrix"
//								case 2: "Position & Vector Simultaneous Set mode"
//								case 3: "Texture Matrix"
//								default: fatalError()
//							}
//						print(mode)
//					} else if command == 0x14 { // MTX_RESTORE
//						let number = try model.read(UInt32.self)
//						mtxRestores.append(number)
//						print(number)
//					} else if command == 0x1B { // MTX_SCALE
//						print(
//							Double(try model.read(UInt32.self)) / 4096,
//							Double(try model.read(UInt32.self)) / 4096,
//							Double(try model.read(UInt32.self)) / 4096
//						)
//					} else if command == 0x20 { // COLOR
//						let color = try model.read(UInt32.self)
//						let red = Double(color & 0b11111) / 0b11111
//						let green = Double((color >> 5) & 0b11111) / 0b11111
//						let blue = Double(color >> 10) / 0b11111
//						
//						print(red, green, blue)
//					} else if command == 0x23 { // VTX_16
//						let xy = try model.read(UInt32.self)
//						let x = Double(xy >> 16) / 4096
//						let y = Double(xy & 0xFFFF) / 4096
//						let z = Double(try model.read(UInt32.self)) / 4096
//						
//						print(x, y, z)
//					} else if command == 0x25 { // VTX_XY
//						let xy = try model.read(UInt32.self)
//						let x = Double(xy >> 16) / 4096
//						let y = Double(xy & 0xFFFF) / 4096
//						
//						print(x, y)
//					} else if command == 0x26 { // VTX_XZ
//						let xz = try model.read(UInt32.self)
//						let x = Double(xz >> 16) / 4096
//						let z = Double(xz & 0xFFFF) / 4096
//						
//						print(x, z)
//					} else if command == 0x27 { // VTX_YZ
//						let yz = try model.read(UInt32.self)
//						let y = Double(yz >> 16) / 4096
//						let z = Double(yz & 0xFFFF) / 4096
//						
//						print(y, z)
////					} else if command == 0x29 { // POLYGON_ATTR
////						0-3   Light 0..3 Enable Flags (each bit: 0=Disable, 1=Enable)
////						4-5   Polygon Mode  (0=Modulation,1=Decal,2=Toon/Highlight Shading,3=Shadow)
////						6     Polygon Back Surface   (0=Hide, 1=Render)  ;Line-segments are always
////						7     Polygon Front Surface  (0=Hide, 1=Render)  ;rendered (no front/back)
////						8-10  Not used
////						11    Depth-value for Translucent Polygons  (0=Keep Old, 1=Set New Depth)
////						12    Far-plane intersecting polygons       (0=Hide, 1=Render/clipped)
////						13    1-Dot polygons behind DISP_1DOT_DEPTH (0=Hide, 1=Render)
////						14    Depth Test, Draw Pixels with Depth    (0=Less, 1=Equal) (usually 0)
////						15    Fog Enable                            (0=Disable, 1=Enable)
////						16-20 Alpha      (0=Wire-Frame, 1..30=Translucent, 31=Solid)
////						21-23 Not used
////						24-29 Polygon ID (00h..3Fh, used for translucent, shadow, and edge-marking)
////						30-31 Not used
////						let attributes = try model.read(UInt32.self)
//					} else if command == 0x40 { // BEGIN_VTXS
//						let argument = try model.read(UInt32.self)
//						let mode = switch argument {
//								case 0: "Separate Triangle(s)"
//								case 1: "Separate Quadliteral(s)"
//								case 2: "Triangle Strips"
//								case 3: "Quadliteral Strips"
//								default: fatalError()
//							}
//						print(mode)
//					} else if command == 0x53 { // UNKNOWN 0x53
//						model.jump(bytes: 0x0c)
//						print()
//						// sometimes 0x53 has a 16-bit word after it (length of args?)
//						break
//					} else {
//						let argumentCount = argumentCountPerCommand[command]!
//						model.jump(bytes: 4 * argumentCount)
//						print()
//					}
//				}
//			}
//			
//			let uniqueRestores = Array(Set(mtxRestores)).sorted()
//			print("MTX_RESTOREs", String(repeating: ".", count: uniqueRestores.count))
//		}
//	}
//}

fileprivate let argumentCountPerCommand = [0x00: 0, 0x10: 1, 0x11: 0, 0x12: 1, 0x13: 1, 0x14: 1, 0x15: 0, 0x16: 16, 0x17: 12, 0x18: 16, 0x19: 12, 0x1a: 9, 0x1b: 3, 0x1c: 3, 0x20: 1, 0x21: 1, 0x22: 1, 0x23: 2, 0x24: 1, 0x25: 1, 0x26: 1, 0x27: 1, 0x28: 1, 0x29: 1, 0x2a: 1, 0x2b: 1, 0x30: 1, 0x31: 1, 0x32: 1, 0x33: 1, 0x34: 1, 0x40: 1, 0x41: 0, 0x53: 3]

fileprivate let commandNames = [0x00: "NOP", 0x10: "MTX_MODE", 0x11: "MTX_PUSH", 0x12: "MTX_POP", 0x13: "MTX_STORE", 0x14: "MTX_RESTORE", 0x15: "MTX_IDENTITY", 0x16: "MTX_LOAD_4x4", 0x17: "MTX_LOAD_4x3", 0x18: "MTX_MULT_4x4", 0x19: "MTX_MULT_4x3", 0x1A: "MTX_MULT_3x3", 0x1B: "MTX_SCALE", 0x1C: "MTX_TRANS", 0x20: "COLOR", 0x21: "NORMAL", 0x22: "TEXCOORD", 0x23: "VTX_16", 0x24: "VTX_10", 0x25: "VTX_XY", 0x26: "VTX_XZ", 0x27: "VTX_YZ", 0x28: "VTX_DIFF", 0x29: "POLYGON_ATTR", 0x2A: "TEXIMAGE_PARAM", 0x2B: "PLTT_BASE", 0x30: "DIF_AMB", 0x31: "SPE_EMI", 0x32: "LIGHT_VECTOR", 0x33: "LIGHT_COLOR", 0x34: "SHININESS", 0x40: "BEGIN_VTXS", 0x41: "END_VTXS", 0x53: "UNKNOWN 0x53"]
