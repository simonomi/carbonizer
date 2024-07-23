import Foundation

//public protocol JSONConvertible: Codable, BinaryConvertible {}
//
//public extension JSONConvertible {
//    init(_ data: Datastream) throws {
//        assert(data.offset == 0) // should only read full files as json (?)
//        self = try JSONDecoder().decode(Self.self, from: Data(data.bytes))
//    }
//
//    func write(to data: Datawriter) {
//        let jsonData = try! JSONEncoder().encode(self) // TODO: panic bad here?
//        data.write(jsonData)
//    }
//}
