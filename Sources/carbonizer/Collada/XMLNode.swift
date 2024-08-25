import Foundation

struct XMLDocument {
	var version: String = "1.0"
	var encoding: String = "utf-8"
	var root: XMLNode
}

struct XMLNode {
	var kind: String
	var attributes: [String: String]
	var body: Body
	
	enum Body {
		case nodes([XMLNode])
		case raw(String)
		
		var isEmpty: Bool {
			switch self {
				case .nodes(let nodes): nodes.isEmpty
				case .raw(let raw): raw.isEmpty
			}
		}
	}
	
	init(
		kind: String,
		id: String? = nil,
		attributes: [String: String?] = [:],
		children: [XMLNode] = []
	) {
		self.init(
			kind: kind,
			id: id,
			attributes: attributes,
			body: .nodes(children)
		)
	}
	
	init(
		kind: String,
		id: String? = nil,
		attributes: [String: String?] = [:],
		children: [some FloatingPoint & LosslessStringConvertible]
	) {
		self.init(
			kind: kind,
			id: id,
			attributes: attributes,
			children: children.map { String(withoutDecimalIfWhole: $0) }
		)
	}
	
	init(
		kind: String,
		id: String? = nil,
		attributes: [String: String?] = [:],
		children: [some LosslessStringConvertible]
	) {
		self.init(
			kind: kind,
			id: id,
			attributes: attributes,
			body: .raw(children.map(String.init).joined(separator: " "))
		)
	}
	
	init(
		kind: String,
		id: String? = nil,
		attributes: [String: String?] = [:],
		body: Body
	) {
		self.kind = kind
		self.attributes = ["id": id]
			.merging(attributes) { $1 }
			.compactMapValues(identity)
		self.body = body
	}
	
	fileprivate func attributesAsString() -> String {
		attributes
			.sorted(by: \.key)
			.map { "\($0)=\($1.debugDescription)" }
			.joined(separator: " ")
	}
	
	func asString(indentation indentationLevel: Int = 0) -> String {
		let indentation = String(repeating: "\t", count: indentationLevel)
		
		let attributes = if attributes.isEmpty {
			""
		} else {
			" \(attributesAsString())"
		}
		
		return if body.isEmpty {
			"\(indentation)<\(kind)\(attributes)/>"
		} else {
			switch body {
				case .nodes(let nodes):
					"""
					\(indentation)<\(kind)\(attributes)>
					\(nodes.asString(indentation: indentationLevel + 1))
					\(indentation)</\(kind)>
					"""
				case .raw(let raw):
					"\(indentation)<\(kind)\(attributes)>\(raw)</\(kind)>"
			}
		}
	}
}

extension [XMLNode] {
	fileprivate func asString(indentation: Int) -> String {
		map { $0.asString(indentation: indentation) }
			.joined(separator: "\n")
	}
}

extension XMLNode {
	static func accessor(
		sourceId: String,
		count: Int,
		offset: Int? = nil,
		stride: Int? = nil,
		_ children: XMLNode...
	) -> Self {
		Self(
			kind: "accessor",
			attributes: [
				"source": "#\(sourceId)",
				"count": String(count),
				"offset": offset.map(String.init),
				"stride": stride.map(String.init)
			],
			children: children
		)
	}
	
	static func asset(_ children: XMLNode...) -> Self {
		Self(kind: "asset", children: children)
	}
	
	static func controller(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "controller", id: id, children: children)
	}
	
	static func collada(_ children: [XMLNode]) -> Self {
		Self(
			kind: "COLLADA",
			attributes: [
				"version": "1.4.1",
				"xmlns": "http://www.collada.org/2005/11/COLLADASchema"
			],
			children: children
		)
	}
	
	static func created(_ date: Date) -> Self {
		Self(
			kind: "created",
			body: .raw(ISO8601DateFormatter().string(from: date))
		)
	}
	
	static func float_array(id: String, _ children: [Double]) -> Self {
		Self(
			kind: "float_array",
			id: id,
			attributes: ["count": String(children.count)],
			children: children
		)
	}
	
	static func geometry(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "geometry", id: id, children: children)
	}
	
	static func input(
		semantic: String,
		sourceId: String,
		offset: Int? = nil
	) -> Self {
		Self(
			kind: "input",
			attributes: [
				"semantic": semantic,
				"source": "#\(sourceId)",
				"offset": offset.map(String.init)
			]
		)
	}
	
	static func instance_controller(controllerId: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "instance_controller",
			attributes: ["url": "#\(controllerId)"],
			children: children
		)
	}
	
	static func instance_geometry(geometryId: String) -> Self {
		Self(
			kind: "instance_geometry",
			attributes: ["url": "#\(geometryId)"]
		)
	}
	
	static func instance_visual_scene(sceneId: String) -> Self {
		Self(
			kind: "instance_visual_scene",
			attributes: ["url": "#\(sceneId)"]
		)
	}
	
	static func joints(_ children: XMLNode...) -> Self {
		Self(kind: "joints", children: children)
	}
	
	static func library_controllers(_ children: XMLNode...) -> Self {
		Self(kind: "library_controllers", children: children)
	}
	
	static func library_geometries(_ children: XMLNode...) -> Self {
		Self(kind: "library_geometries", children: children)
	}
	
	static func library_visual_scenes(_ children: XMLNode...) -> Self {
		Self(kind: "library_visual_scenes", children: children)
	}
	
	static func mesh(_ children: XMLNode...) -> Self {
		Self(kind: "mesh", children: children)
	}
	
	static func modified(_ date: Date) -> Self {
		Self(
			kind: "modified",
			body: .raw(ISO8601DateFormatter().string(from: date))
		)
	}
	
	static func name_array(id: String, _ children: [String]) -> Self {
		Self(
			kind: "Name_array",
			id: id,
			attributes: ["count": String(children.count)],
			children: children
		)
	}
	
	static func node(
		id: String? = nil,
		sid: String? = nil,
		name: String? = nil,
		type: String? = nil,
		_ children: XMLNode...
	) -> Self {
		.node(id: id, sid: sid, name: name, type: type, children)
	}
	
	static func node(
		id: String? = nil,
		sid: String? = nil,
		name: String? = nil,
		type: String? = nil,
		_ children: [XMLNode]
	) -> Self {
		Self(
			kind: "node",
			id: id,
			attributes: [
				"sid": sid,
				"type": type,
				"name": name
			],
			children: children
		)
	}
	
	static func p(_ children: [Int]) -> Self {
		Self(kind: "p", children: children)
	}
	
	static func param(name: String, type: String) -> Self {
		Self(
			kind: "param",
			attributes: [
				"name": name,
				"type": type
			]
		)
	}
	
	static func polylist(count: Int, _ children: XMLNode...) -> Self {
		Self(
			kind: "polylist",
			attributes: ["count": String(count)],
			children: children
		)
	}
	
	static func scene(_ children: XMLNode...) -> Self {
		Self(kind: "scene", children: children)
	}
	
	static func skeleton(_ id: String) -> Self {
		Self(kind: "skeleton", body: .raw("#\(id)"))
	}
	
	static func skin(sourceId: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "skin",
			attributes: ["source": "#\(sourceId)"],
			children: children
		)
	}
	
	static func source(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "source", id: id, children: children)
	}
	
	static func technique_common(_ children: XMLNode...) -> Self {
		Self(kind: "technique_common", children: children)
	}
	
	static func translate(_ vector: SIMD3<Double>) -> Self {
		Self(kind: "translate", body: .raw(vector.spaceSeparated()))
	}
	
	static func v(_ children: [Int]) -> Self {
		Self(kind: "v", children: children)
	}
	
	static func vcount(_ children: [Int]) -> Self {
		Self(kind: "vcount", children: children)
	}
	
	static func vertex_weights(count: Int, _ children: XMLNode...) -> Self {
		Self(
			kind: "vertex_weights",
			attributes: ["count": String(count)],
			children: children
		)
	}
	
	static func vertices(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "vertices", id: id, children: children)
	}
	
	static func visual_scene(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "visual_scene", id: id, children: children)
	}
}

extension SIMD3<Double> {
	func spaceSeparated() -> String {
		let x = String(withoutDecimalIfWhole: x)
		let y = String(withoutDecimalIfWhole: y)
		let z = String(withoutDecimalIfWhole: z)
		
		return "\(x) \(y) \(z)"
	}
}
