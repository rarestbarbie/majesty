import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension PopulationReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("S") case sex(Sex)
        @tag("T") case location(Address)
    }
}
extension PopulationReport.Filter: CustomStringConvertible, LosslessStringConvertible {}
extension PopulationReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
