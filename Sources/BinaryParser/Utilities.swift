//
//  Utilities.swift
//  
//
//  Created by simon pellerin on 2023-12-06.
//

extension String {
	enum Direction {
		case leading, trailing
	}
	
	func padded(
		toLength targetLength: Int,
		with character: Character,
		from direction: Direction = .leading
	) -> Self {
		guard targetLength > count else { return self }
		let padding = String(repeating: character, count: targetLength - count)
		return switch direction {
			case .leading: padding + self
			case .trailing: self + padding
		}
	}
}
