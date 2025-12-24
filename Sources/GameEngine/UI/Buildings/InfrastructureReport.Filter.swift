import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension InfrastructureReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable {
        @tag("T") case location(Address)
    }
}
extension InfrastructureReport.Filter: CustomStringConvertible, LosslessStringConvertible {}
extension InfrastructureReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
