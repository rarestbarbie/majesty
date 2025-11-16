import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension PopulationReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("A") case all
        @tag("T") case location(Address)
    }
}
extension PopulationReport.Filter: CustomStringConvertible {}
extension PopulationReport.Filter: LosslessStringConvertible {}
extension PopulationReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
extension PopulationReport.Filter: PersistentSelectionFilter {
    typealias Subject = PopContext
    static func ~= (self: Self, value: PopContext) -> Bool {
        switch self {
        case .all: true
        case .location(let location): location == value.state.tile
        }
    }
}
