//
//  BinaryFile.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct BinaryFile {
	var name: String
	var contents: Data
	
	var fileExtension: String? {
		if name.contains(".") {
			return name.split(separator: ".").last.map(String.init)
		} else {
			return nil
		}
	}
	
	var magicId: String? {
		String(bytes: contents.prefix(4), encoding: .utf8)
	}
	
	func carbonized() throws -> FSFile {
		switch fileExtension {
			case ".mar":
				return try MARArchive(from: self).carbonized()
			default: break
		}
		
		return .binaryFile(self)
	}
	
	func uncarbonized() throws -> FSFile {
		switch fileExtension {
			case "nds":
				return try NDSFile(from: self).uncarbonized()
			default: break
		}
		
		// TODO: re-enable once they'll be recarbonized
//		switch magicId {
//			case "MAR\0":
//				return try MARArchive(from: self).uncarbonized()
//			default: break
//		}
		
		return .binaryFile(self)
	}
}
