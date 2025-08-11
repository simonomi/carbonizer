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
			body: .raw(children.map { String($0) }.joined(separator: " "))
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
			.compactMapValues(\.self)
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
	
	static func animation(_ children: [XMLNode]) -> Self {
		Self(kind: "animation", children: children)
	}
	
	static func asset(_ children: XMLNode...) -> Self {
		Self(kind: "asset", children: children)
	}
	
	static func bind_material(_ children: XMLNode...) -> Self {
		Self(kind: "bind_material", children: children)
	}
	
	static func bind_vertex_input(semantic: String, input_semantic: String) -> Self {
		Self(
			kind: "bind_vertex_input",
			attributes: [
				"semantic": semantic,
				"input_semantic": input_semantic
			],
			children: []
		)
	}
	
	static func channel(sourceId: String, target: String) -> Self {
		Self(
			kind: "channel",
			attributes: [
				"source": "#\(sourceId)",
				"target": target
			],
			children: []
		)
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
	
	static func diffuse(_ children: XMLNode...) -> Self {
		Self(kind: "diffuse", children: children)
	}
	
	static func effect(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "effect", id: id, children: children)
	}
	
	static func float(sid: String, _ value: Double) -> Self {
		Self(
			kind: "float",
			attributes: ["sid": sid],
			body: .raw(String(withoutDecimalIfWhole: value))
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
	
	static func image(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "image", id: id, children: children)
	}
	
	static func index_of_refraction(_ ior: Double) -> Self {
		Self(
			kind: "index_of_refraction",
			children: [
				.float(sid: "ior", ior)
			]
		)
	}
	
	static func init_from(_ fileName: String) -> Self {
		Self(
			kind: "init_from",
			body: .raw(fileName)
		)
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
	
	static func instance_effect(effectId: String) -> Self {
		Self(
			kind: "instance_effect",
			attributes: ["url": "#\(effectId)"]
		)
	}
	
	static func instance_geometry(geometryId: String) -> Self {
		Self(
			kind: "instance_geometry",
			attributes: ["url": "#\(geometryId)"]
		)
	}
	
	static func instance_material(symbol: String, target: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "instance_material",
			attributes: [
				"symbol": symbol,
				"target": "#\(target)"
			],
			children: children
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
	
	static func lambert(_ children: XMLNode...) -> Self {
		Self(kind: "lambert", children: children)
	}
	
	static func library_animations(_ children: XMLNode...) -> Self {
		Self(kind: "library_animations", children: children)
	}
	
	static func library_controllers(_ children: XMLNode...) -> Self {
		Self(kind: "library_controllers", children: children)
	}
	
	static func library_effects(_ children: [XMLNode]) -> Self {
		Self(kind: "library_effects", children: children)
	}
	
	static func library_geometries(_ children: XMLNode...) -> Self {
		Self(kind: "library_geometries", children: children)
	}
	
	static func library_materials(_ children: [XMLNode]) -> Self {
		Self(kind: "library_materials", children: children)
	}
	
	static func library_visual_scenes(_ children: XMLNode...) -> Self {
		Self(kind: "library_visual_scenes", children: children)
	}
	
	static func material(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "material", id: id, children: children)
	}
	
	static func matrix(sid: String, _ matrix: Matrix4x3<Double>) -> Self {
		Self(
			kind: "matrix",
			attributes: ["sid": sid],
			body: .raw(
				matrix
					.as4x4Array()
					.map { String(withoutDecimalIfWhole: $0) }
					.joined(separator: " ")
			)
		)
	}
	
	static func mesh(_ children: [XMLNode]) -> Self {
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
	
	static func newparam(sid: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "newparam",
			attributes: ["sid": sid],
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
	
	static func polylist(count: Int, material: String? = nil, _ children: XMLNode...) -> Self {
		Self(
			kind: "polylist",
			attributes: [
				"count": String(count),
				"material": material
			],
			children: children
		)
	}
	
	static func profile_COMMON(_ children: XMLNode...) -> Self {
		Self(kind: "profile_COMMON", children: children)
	}
	
	static func sampler(id: String, _ children: XMLNode...) -> Self {
		Self(kind: "sampler", id: id, children: children)
	}
	
	static func sampler2D(_ children: XMLNode...) -> Self {
		Self(kind: "sampler2D", children: children)
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
	
	static func source(id: String?, _ children: XMLNode...) -> Self {
		Self(kind: "source", id: id, children: children)
	}
	
	static func source(_ body: String) -> Self {
		Self(kind: "source", body: .raw(body))
	}
	
	static func surface(type: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "surface",
			attributes: ["type": type],
			children: children
		)
	}
	
	static func technique(sid: String, _ children: XMLNode...) -> Self {
		Self(
			kind: "technique",
			attributes: ["sid": sid],
			children: children
		)
	}
	
	static func technique_common(_ children: XMLNode...) -> Self {
		Self(kind: "technique_common", children: children)
	}
	
	static func technique_common(_ children: [XMLNode]) -> Self {
		Self(kind: "technique_common", children: children)
	}
	
	static func texture(texture: String, texcoord: String) -> Self {
		Self(
			kind: "texture",
			attributes: [
				"texture": texture,
				"texcoord": texcoord
			],
			children: []
		)
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
