import BinaryParser
import Foundation

protocol FileData: BinaryConvertible {
    static var fileExtension: String { get }
    
    associatedtype Packed: FileData where Packed.Unpacked == Self
    init(_ packed: Packed)
    
    associatedtype Unpacked: FileData where Unpacked.Packed == Self
    init(_ unpacked: Unpacked)
}

extension FileData where Self: Codable {
    init(_ data: Datastream) throws {
        assert(data.offset == 0) // should only read full files as json (?)
        self = try JSONDecoder().decode(Self.self, from: Data(data.bytes))
    }
    
    func write(to data: Datawriter) {
        // TODO: panic bad here?
        let jsonData = try! JSONEncoder(.prettyPrinted).encode(self)
        data.write(jsonData)
    }
}

extension FileData {
    func packed() -> Packed { Packed(self) }
    func unpacked() -> Unpacked { Unpacked(self) }
}

extension Datastream: FileData {
    typealias Packed = Datastream
    typealias Unpacked = Datastream
    static let fileExtension = ""
}
