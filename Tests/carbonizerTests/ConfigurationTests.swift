import Testing
import Foundation

@testable import carbonizer

@Test
func defaultConfigurationIsValid() throws {
	_ = try CarbonizerConfiguration(
		decoding: CarbonizerConfiguration.defaultConfigurationString
	)
}
