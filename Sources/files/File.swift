//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

enum File {
	case binaryFile(BinaryFile)
	case ndsFile(NDSFile)
	case marArchive(MARArchive)
	case dtxFile(DTXFile)
	case dmgFile(DMGFile)
	case mm3File(MM3File)
	case dmsFile(DMSFile)
	case mpmFile(MPMFile)
	case textureFile(TextureFile)
	case rlsFile(RLSFile)
	case dexFile(DEXFile)
	
	init(from path: URL) throws {
		let data = try Data(contentsOf: path)
		try self.init(named: path.lastPathComponent, from: data)
	}
	
	init(named name: String, from data: Data) throws {
		let fileExtension: String?
		if name.hasSuffix(".json") {
			fileExtension = name.dropLast(5).split(separator: ".").last.map(String.init) ?? ".json"
		} else if name.contains(".") {
			fileExtension = name.split(separator: ".").last.map(String.init)
		} else {
			fileExtension = nil
		}
		
		let magicId = String(bytes: data.prefix(4), encoding: .utf8)
		
		switch fileExtension {
			case "nds":
				inputIsCarbonized = true
				self = .ndsFile(try NDSFile(named: name, from: data))
				return
			case "dtx":
				inputIsCarbonized = false
				self = .dtxFile(try DTXFile(named: name, json: data))
				return
			case "dmg":
				inputIsCarbonized = false
				self = .dmgFile(try DMGFile(named: name, json: data))
				return
			case "mm3":
				inputIsCarbonized = false
				self = .mm3File(try MM3File(named: name, json: data))
				return
			case "dms":
				inputIsCarbonized = false
				self = .dmsFile(try DMSFile(named: name, json: data))
				return
			case "mpm":
				inputIsCarbonized = false
				self = .mpmFile(try MPMFile(named: name, json: data))
				return
			case "rls":
				inputIsCarbonized = false
				self = .rlsFile(try RLSFile(named: name, json: data))
				return
			case "dex":
				inputIsCarbonized = false
				self = .dexFile(try DEXFile(named: name, json: data))
				return
			default: break
		}
		
		switch magicId {
			case "MAR\0":
				if !fastMode {
					inputIsCarbonized = true
					self = .marArchive(try MARArchive(named: name, from: data))
					return
				}
			case "DTX\0":
				inputIsCarbonized = true
				self = .dtxFile(try DTXFile(named: name, from: data))
				return
			case "DMG\0":
				inputIsCarbonized = true
				self = .dmgFile(try DMGFile(named: name, from: data))
				return
			case "MM3\0":
				inputIsCarbonized = true
				self = .mm3File(try MM3File(named: name, from: data))
				return
			case "DMS\0":
				inputIsCarbonized = true
				self = .dmsFile(try DMSFile(named: name, from: data))
				return
			case "MPM\0":
				inputIsCarbonized = true
				self = .mpmFile(try MPMFile(named: name, from: data))
				return
			case "RLS\0":
				inputIsCarbonized = true
				self = .rlsFile(try RLSFile(named: name, from: data))
				return
			case "DEX\0":
				inputIsCarbonized = true
				self = .dexFile(try DEXFile(named: name, from: data))
				return
			default: break
		}
		
		self = .binaryFile(BinaryFile(named: name, contents: data))
	}
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		switch self {
			case .binaryFile(let binaryFile):
				try binaryFile.save(in: path, carbonized: carbonized, with: metadata)
			case .ndsFile(let ndsFile):
				try ndsFile.save(in: path, carbonized: carbonized, with: metadata)
			case .marArchive(let marArchive):
				try marArchive.save(in: path, carbonized: carbonized, with: metadata)
			case .dtxFile(let dtxFile):
				try dtxFile.save(in: path, carbonized: carbonized, with: metadata)
			case .dmgFile(let dmgFile):
				try dmgFile.save(in: path, carbonized: carbonized, with: metadata)
			case .mm3File(let mm3File):
				try mm3File.save(in: path, carbonized: carbonized, with: metadata)
			case .dmsFile(let dmsFile):
				try dmsFile.save(in: path, carbonized: carbonized, with: metadata)
			case .mpmFile(let mpmFile):
				try mpmFile.save(in: path, carbonized: carbonized, with: metadata)
			case .textureFile(let textureFile):
				try textureFile.save(in: path, carbonized: carbonized, with: metadata)
			case .rlsFile(let rlsFile):
				try rlsFile.save(in: path, carbonized: carbonized, with: metadata)
			case .dexFile(let dexFile):
				try dexFile.save(in: path, carbonized: carbonized, with: metadata)
		}
	}
	
	var name: String {
		switch self {
			case .binaryFile(let binaryFile):
				return binaryFile.name
			case .ndsFile(let ndsFile):
				return ndsFile.name
			case .marArchive(let marArchive):
				return marArchive.name
			case .dtxFile(let dtxFile):
				return dtxFile.name
			case .dmgFile(let dmgFile):
				return dmgFile.name
			case .mm3File(let mm3File):
				return mm3File.name
			case .dmsFile(let dmsFile):
				return dmsFile.name
			case .mpmFile(let mpmFile):
				return mpmFile.name
			case .textureFile(let textureFile):
				return textureFile.name
			case .rlsFile(let rlsFile):
				return rlsFile.name
			case .dexFile(let dexFile):
				return dexFile.name
		}
	}
	
	func renamed(to newName: String) -> File {
		switch self {
			case .binaryFile(var binaryFile):
				binaryFile.name = newName
				return .binaryFile(binaryFile)
			case .ndsFile(var ndsFile):
				ndsFile.name = newName
				return .ndsFile(ndsFile)
			case .marArchive(var marArchive):
				marArchive.name = newName
				return .marArchive(marArchive)
			case .dtxFile(var dtxFile):
				dtxFile.name = newName
				return .dtxFile(dtxFile)
			case .dmgFile(var dmgFile):
				dmgFile.name = newName
				return .dmgFile(dmgFile)
			case .mm3File(var mm3File):
				mm3File.name = newName
				return .mm3File(mm3File)
			case .dmsFile(var dmsFile):
				dmsFile.name = newName
				return .dmsFile(dmsFile)
			case .mpmFile(var mpmFile):
				mpmFile.name = newName
				return .mpmFile(mpmFile)
			case .textureFile(var textureFile):
				textureFile.name = newName
				return .textureFile(textureFile)
			case .rlsFile(var rlsFile):
				rlsFile.name = newName
				return .rlsFile(rlsFile)
			case .dexFile(var dexFile):
				dexFile.name = newName
				return .dexFile(dexFile)
		}
	}
}

extension Data {
	init(from file: File) throws {
		switch file {
			case .binaryFile(let binaryFile):
				self = binaryFile.contents
			case .ndsFile(let ndsFile):
				self = try Data(from: ndsFile)
			case .marArchive(let marArchive):
				self = try Data(from: marArchive)
			case .dtxFile(let dtxFile):
				self = try Data(from: dtxFile)
			case .dmgFile(let dmgFile):
				self = try Data(from: dmgFile)
			case .mm3File(let mm3File):
				self = try Data(from: mm3File)
			case .dmsFile(let dmsFile):
				self = try Data(from: dmsFile)
			case .mpmFile(let mpmFile):
				self = try Data(from: mpmFile)
			case .textureFile:
				fatalError("unable to save a TextureFile as data")
			case .rlsFile(let rlsFile):
				self = try Data(from: rlsFile)
			case .dexFile(let dexFile):
				self = try Data(from: dexFile)
		}
	}
}
