import XCTest
import Foundation

@testable import carbonizer

class ConfigurationTests: XCTestCase {
	func testDefaultConfiguration() throws {
		_ = try CarbonizerConfiguration(
			decoding: CarbonizerConfiguration.defaultConfiguration
		)
	}
}
