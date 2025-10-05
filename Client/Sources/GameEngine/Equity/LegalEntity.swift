import GameState
import JavaScriptInterop
import JavaScriptKit

enum LegalEntity: Equatable, Hashable {
    case factory(FactoryID)
    case pop(PopID)
}
extension LegalEntity: LosslessStringConvertible {
    @inlinable public init?(_ id: some StringProtocol) {
        guard
        let first: String.Index = id.unicodeScalars.indices.first,
        let discriminant: Class = .init(rawValue: id.unicodeScalars[first]),
        let index: Int32 = .init(id[id.index(after: first)...]) else {
            return nil
        }

        switch discriminant {
        case .F:   self = .factory(.init(rawValue: index))
        case .P:   self = .pop(.init(rawValue: index))
        }
    }
}
extension LegalEntity: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .factory(let id):   "F\(id.rawValue)"
        case .pop(let id):       "P\(id.rawValue)"
        }
    }
}
extension LegalEntity: ConvertibleToJSString, LoadableFromJSString {}
