//
//  RLSFile.swift
//
//
//  Created by simon pellerin on 2023-06-30.
//

import Foundation

struct RLSFile {
	var name: String
	
	var kasekis: [Kaseki?]
	
	struct Kaseki: Codable, Equatable {
		var _label: String?
		
		var unknown1: Bool
		var unknown2: Bool
		var unbreakable: Bool
		var destroyable: Bool
		
		var unknown3: UInt8
		var unknown4: UInt8
		var unknown5: UInt8
		var unknown6: UInt8
		
		var fossilImage: UInt32
		var rockImage: UInt32
		var fossilConfig: UInt32
		var rockConfig: UInt32
		var buyPrice: UInt32
		var sellPrice: UInt32
		
		var unknown7: UInt32
		var unknown8: UInt32
		var fossilName: UInt32
		var unknown10: UInt32
		
		var time: UInt32
		var passingScore: UInt32
		
		var unknown11: UInt32
		var unknown12: UInt32
		var unknown13: UInt32
		
		var unknown14: UInt32?
		var unknown15: UInt32?
	}
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".rls.json")
			try jsonData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
}
