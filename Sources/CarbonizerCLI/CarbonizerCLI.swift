// this fixes using `stdout` on linux
#if os(Linux)
@preconcurrency import Glibc
#endif

import Carbonizer
import ANSICodes
import ArgumentParser
import Foundation

@main
struct CarbonizerCLI: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "carbonizer",
		abstract: "A Fossil Fighters ROM-hacking tool",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode (default: --auto)")
	var compressionMode: CLIConfiguration.CompressionMode?
	
	@Argument(
		help: "The files to pack/unpack",
		completion: .file(),
		transform: URL.fromFilePath
	)
	var inputFilePaths = [URL]()
	
	func run() async throws {
#if !IN_CI
		let start = Date.now
#endif
		
#if !IN_CI && os(macOS)
		let configurationPath = URL(filePath: "/Users/simonomi/Desktop/config.json5")
#else
		let configurationPath = Bundle.main.executableURL?
			.deletingLastPathComponent()
			.appending(component: "config.json5") ?? URL(filePath: "config.json5")
#endif
		
		let cliConfiguration: CLIConfiguration
		do {
			cliConfiguration = try CLIConfiguration(contentsOf: configurationPath)
		} catch let error as DecodingError {
			print(error.configurationFormatting(path: configurationPath))
			waitForInput()
			return
		} catch {
			print("\(configurationPath.path(percentEncoded: false)): \(error)")
			waitForInput()
			return
		}
		
		let logHandler: (@Sendable (String) -> Void)?
		if cliConfiguration.showProgress {
			let inputTerminalWidth = terminalSize().width
			let terminalWidth = if inputTerminalWidth == 0 {
				9999
			} else {
				inputTerminalWidth
			}
			
			logHandler = {
				// TODO: do these ansi codes work on windows cmd?
				print($0.prefix(max(0, terminalWidth - 3)) + "...\(.clearToEndOfLine)", terminator: "\r")
				fflush(stdout)
			}
		} else {
			logHandler = nil
		}
		
		do {
			let configuration = try Configuration(
				cliConfiguration,
				logHandler: logHandler
			)
			
			let filePaths = inputFilePaths + cliConfiguration.inputFiles.map(URL.fromFilePath)
			
			guard filePaths.isNotEmpty else {
				throw NoInputFiles()
			}
			
			for filePath in filePaths {
				let outputFolder = cliConfiguration.outputFolder.map(URL.fromFilePath) ?? filePath.deletingLastPathComponent()
				
				if cliConfiguration.hotReloading {
					try await Carbonizer.monitor(
						filePath,
						into: outputFolder,
						configuration: configuration
					)
				} else {
					switch cliConfiguration.compressionMode {
						case .auto:
							try Carbonizer.auto(
								filePath,
								into: outputFolder,
								configuration: configuration
							)
						case .pack:
							try Carbonizer.pack(
								filePath,
								into: outputFolder,
								configuration: configuration
							)
						case .unpack:
							try Carbonizer.unpack(
								filePath,
								into: outputFolder,
								configuration: configuration
							)
					}
				}
			}
		} catch {
			var standardError = FileHandle.standardError
			if cliConfiguration.useColor {
				print("\(.red)error:\(.normal)", error, to: &standardError)
			} else {
				print("error:", String(describing: error).removingANSICodes(), to: &standardError)
			}
			
			if cliConfiguration.keepWindowOpen.isTrueOnError {
				waitForInput()
			}
		}
		
#if !IN_CI
		print("\(.green)total", -start.timeIntervalSinceNow, "\(.normal)")
#endif
	}
}
