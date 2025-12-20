import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension ProductionReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("A") case all
        @tag("T") case location(Address)
    }
}
extension ProductionReport.Filter: CustomStringConvertible {}
extension ProductionReport.Filter: LosslessStringConvertible {}
extension ProductionReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
extension ProductionReport.Filter: PersistentSelectionFilter {
    typealias Subject = FactorySnapshot
    static func ~= (self: Self, value: FactorySnapshot) -> Bool {
        switch self {
        case .all: true
        case .location(let location): location == value.state.tile
        }
    }
}
