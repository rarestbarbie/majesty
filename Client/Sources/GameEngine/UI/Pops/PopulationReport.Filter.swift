import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension PopulationReport {
    @frozen public enum Filter: Equatable, Hashable {
        case all
        case location(Address)
    }
}
extension PopulationReport.Filter {
    @inlinable var type: PopulationReport.FilterType {
        switch self {
        case .all:      .all
        case .location: .location
        }
    }
}
extension PopulationReport.Filter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .all: "\(PopulationReport.FilterType.all.rawValue)"
        case .location(let self): "\(PopulationReport.FilterType.location.rawValue)\(self)"
        }
    }
}
extension PopulationReport.Filter: LosslessStringConvertible {
    @inlinable public init?(_ string: String) {
        guard
        let first: String.Index = string.indices.first,
        let type: PopulationReport.FilterType = .init(
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
extension PopulationReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
extension PopulationReport.Filter: PersistentSelectionFilter {
    typealias Subject = PopContext
    static func ~= (self: Self, value: PopContext) -> Bool {
        switch self {
        case .all: true
        case .location(let location): location == value.state.home
        }
    }
}
