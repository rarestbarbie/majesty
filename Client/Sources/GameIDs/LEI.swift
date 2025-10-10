@frozen public enum LEI: Equatable, Hashable {
    case factory(FactoryID)
    case pop(PopID)
}
extension LEI: LosslessStringConvertible {
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
extension LEI: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .factory(let id):   "\(Class.F)\(id.rawValue)"
        case .pop(let id):       "\(Class.P)\(id.rawValue)"
        }
    }
}
