import GameEconomy
import JavaScriptKit
import JavaScriptInterop

@frozen public enum CashFlowItem: Equatable, Hashable, Comparable {
    case resource(Resource)
    case workers
    case clerks
    // TODO: include wages, labor cost, etc.
}
extension CashFlowItem {
    @inlinable var type: CashFlowItemType {
        switch self {
        case .resource: .resource
        case .workers: .workers
        case .clerks: .clerks
        }
    }
}
extension CashFlowItem: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .resource(let resource): "\(self.type.rawValue)\(resource)"
        case .workers: "\(self.type.rawValue)"
        case .clerks: "\(self.type.rawValue)"
        }
    }
}
extension CashFlowItem: LosslessStringConvertible {
    @inlinable public init?(_ string: String) {
        guard
        let first: String.Index = string.indices.first,
        let type: CashFlowItemType = .init(
            rawValue: Unicode.Scalar.init(string.utf8[first])
        ) else {
            return nil
        }

        let next: String.Index = string.utf8.index(after: first)

        switch type {
        case .resource:
            guard let resource: Resource = .init(string[next...]) else {
                return nil
            }
            self = .resource(resource)

        case .workers:
            self = .workers

        case .clerks:
            self = .clerks
        }
    }
}
extension CashFlowItem: ConvertibleToJSString, LoadableFromJSString {
}
