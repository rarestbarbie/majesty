import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension InfrastructureReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("A") case all
        @tag("T") case location(Address)
    }
}
extension InfrastructureReport.Filter: CustomStringConvertible {}
extension InfrastructureReport.Filter: LosslessStringConvertible {}
extension InfrastructureReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
extension InfrastructureReport.Filter: PersistentSelectionFilter {
    typealias Subject = BuildingSnapshot
    static func ~= (self: Self, value: BuildingSnapshot) -> Bool {
        switch self {
        case .all: true
        case .location(let location): location == value.state.tile
        }
    }
}
