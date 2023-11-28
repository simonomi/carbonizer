//
//  main.swift
//  
//
//  Created by alice on 2023-11-25.
//

import ArgumentParser

@main
struct carbonizer: ParsableCommand {
	@Flag(name: .shortAndLong)
	var verbose: Int
	
	mutating func run() throws {
		print("Verbosity level: \(verbose)")
	}
}
