import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension ProductionReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("T") case location(Address)
    }
}
extension ProductionReport.Filter: CustomStringConvertible, LosslessStringConvertible {}
extension ProductionReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
