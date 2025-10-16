import GameIDs
import JavaScriptKit
import JavaScriptInterop

@StringUnion @frozen public enum CashFlowItem: Equatable, Hashable, Comparable {
    @tag("R") case resource(Resource)
    @tag("W") case workers
    @tag("C") case clerks
    // TODO: include wages, labor cost, etc.
}
extension CashFlowItem: LosslessStringConvertible {}
extension CashFlowItem: ConvertibleToJSString, LoadableFromJSString {}
