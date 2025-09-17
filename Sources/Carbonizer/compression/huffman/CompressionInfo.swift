enum Huffman {
	struct CompressionInfo: Codable {
		var dataSize: UInt8
		var tree: Node?
		
		indirect enum Node: Codable {
			case symbol(Byte)
			case branch(left: Self, right: Self)
			
			enum BranchCodingKeys: CodingKey {
				case left, right
			}
			
			init(from decoder: any Decoder) throws {
				do {
					let symbol = try decoder.singleValueContainer().decode(Byte.self)
					
					self = .symbol(symbol)
				} catch {
					let container = try decoder.container(keyedBy: BranchCodingKeys.self)
					
					let left = try container.decode(Self.self, forKey: .left)
					let right = try container.decode(Self.self, forKey: .right)
					
					self = .branch(left: left, right: right)
				}
			}
			
			func encode(to encoder: any Encoder) throws {
				switch self {
					case .symbol(let byte):
						var container = encoder.singleValueContainer()
						try container.encode(byte)
					case .branch(let left, let right):
						var container = encoder.container(keyedBy: BranchCodingKeys.self)
						
						try container.encode(left, forKey: .left)
						try container.encode(right, forKey: .right)
				}
			}
			
			init(
				traversing data: ArraySlice<Byte>,
				at currentOffset: Int,
				isData: Bool = false
			) {
				let nodeData = data[currentOffset]
				
				if isData {
					self = .symbol(nodeData)
				} else {
					let huffmanNode = Huffman.DecompressionNode(nodeData: nodeData)
					
					self = .branch(
						left: Self(
							traversing: data,
							at: huffmanNode.leftOffset(currentOffset: currentOffset),
							isData: huffmanNode.leftIsData
						),
						right: Self(
							traversing: data,
							at: huffmanNode.rightOffset(currentOffset: currentOffset),
							isData: huffmanNode.rightIsData
						)
					)
				}
			}
			
			func mermaidDiagram() -> String {
				var nodeIndex = 0
				return (
					["```mermaid", "graph TD"] +
					mermaidConnections(&nodeIndex).connections.map { "\t" + $0 } +
					["```"]
				)
				.joined(separator: "\n")
			}
			
			private func mermaidConnections(_ index: inout Int) -> (name: String, connections: [String]) {
				switch self {
					case .symbol(let byte):
						let myName = "0x" + String(byte, radix: 16, uppercase: true)
						return (
							myName,
							["style \(myName) fill:#00c7de"]
						)
					case .branch(let left, let right):
						let myName = String(index)
						
						index += 1
						let left = left.mermaidConnections(&index)
						let right = right.mermaidConnections(&index)
						
						return (
							myName,
							[
								"\(myName) --> \(left.name)",
								"\(myName) --> \(right.name)"
							] + left.connections + right.connections
						)
				}
			}
		}
	}
}
