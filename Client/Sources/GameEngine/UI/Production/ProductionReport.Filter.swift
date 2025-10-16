import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension ProductionReport {
    @frozen public enum Filter: Equatable, Hashable {
        case all
        case location(Address)
    }
}
extension ProductionReport.Filter {
    @inlinable var type: ProductionReport.FilterType {
        switch self {
        case .all:      .all
        case .location: .location
        }
    }
}
extension ProductionReport.Filter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .all: "\(ProductionReport.FilterType.all.rawValue)"
        case .location(let self): "\(ProductionReport.FilterType.location.rawValue)\(self)"
        }
    }
}
extension ProductionReport.Filter: LosslessStringConvertible {
    @inlinable public init?(_ string: String) {
        guard
        let first: String.Index = string.indices.first,
        let type: ProductionReport.FilterType = .init(
            rawValue: Unicode.Scalar.init(string.utf8[first])
        ) else {
            return nil
        }

        let next: String.Index = string.utf8.index(after: first)

        switch type {
        case .all:
            self = .all

        case .location:
            guard let location: Address = .init(string[next...]) else {
                return nil
            }
            self = .location(location)
        }
    }
}
extension ProductionReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
extension ProductionReport.Filter: PersistentSelectionFilter {
    typealias Subject = FactoryContext
    static func ~= (self: Self, value: FactoryContext) -> Bool {
        switch self {
        case .all: true
        case .location(let location): location == value.state.tile
        }
    }
}
