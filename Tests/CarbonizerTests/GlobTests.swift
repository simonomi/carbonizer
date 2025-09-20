import Testing
import Foundation

@testable import Carbonizer

//@Test
//func defaultConfigurationIsValid() throws {
//	_ = try Configuration(
//		decoding: Configuration.defaultConfigurationString
//	)
//}

@Suite
struct Globs {
	// examples: "text/japanese", "episode/*", "model/**", "**/arc*"
	@Test
	func allLiterals() throws {
		let glob = try Glob(raw: "text/japanese")
		
		#expect(glob.matches(["text", "japanese"]))
		#expect(!glob.matches(["text", "notJapanese"]))
		#expect(!glob.matches(["notText", "japanese"]))
		#expect(!glob.matches(["notText", "notJapanese"]))
		#expect(!glob.matches(["text", "japanese", "more", "things"]))
		#expect(!glob.matches(["text"]))
	}
	
	@Test
	func simpleWildcard() throws {
		let glob = try Glob(raw: "episode/*")
		
		#expect(glob.matches(["episode", "0001"]))
		#expect(glob.matches(["episode", "e0002"]))
		#expect(!glob.matches(["episode", "sub", "folder"]))
		#expect(!glob.matches(["episode"]))
		#expect(!glob.matches(["notEpisode", "0001"]))
	}
	
	@Test
	func recursiveWildcard() throws {
		let glob = try Glob(raw: "model/**")
		
		#expect(glob.matches(["model", "battle"]))
		#expect(glob.matches(["model", "fieldchar"]))
		#expect(glob.matches(["model", "battle", "arc"]))
		#expect(!glob.matches(["model"]))
		#expect(!glob.matches(["notModel", "0001"]))
	}
	
	@Test
	func partialWildcard() throws {
		let glob = try Glob(raw: "model/arc*")
		
		#expect(!glob.matches(["model", "battle"]))
		#expect(glob.matches(["model", "arc"]))
		#expect(glob.matches(["model", "arcdin"]))
		#expect(glob.matches(["model", "arcscenecsv"]))
		#expect(!glob.matches(["model"]))
		#expect(!glob.matches(["notModel", "0001"]))
	}
	
	@Test
	func recursiveAndPartialWildcard() throws {
		let glob = try Glob(raw: "**/arc*")
		
		#expect(!glob.matches(["model", "battle"]))
		#expect(glob.matches(["model", "battle", "arc"]))
		#expect(glob.matches(["model", "arc"]))
		#expect(glob.matches(["model", "arcdin"]))
		#expect(glob.matches(["model", "arcscenecsv"]))
		#expect(!glob.matches(["model"]))
		#expect(!glob.matches(["notModel", "0001"]))
		#expect(glob.matches(["notModel", "arc"]))
		#expect(glob.matches(["image", "arcdin"]))
		#expect(glob.matches(["image", "one", "two", "three", "arcdin"]))
	}
	
//	@Test
//	func onlyUnpackConfiguration() throws {
//		let rawConfiguration = #"{ "onlyUnpack": ["model/fieldchar/**"] }"#.data(using: .utf8)!
//		let configuration = try JSONDecoder().decode(Configuration.self, from: rawConfiguration)
//		
//		#expect(configuration.shouldUnpack(["model", "fieldchar", "cha01a_01"]))
//	}
}
