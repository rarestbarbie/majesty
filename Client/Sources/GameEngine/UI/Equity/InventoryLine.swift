import GameIDs
import JavaScriptKit
import JavaScriptInterop

@StringUnion public enum InventoryLine: Equatable, Hashable {
    @tag("l") case l(Resource)
    @tag("e") case e(Resource)
    @tag("x") case x(Resource)
    @tag("o") case o(Resource)
}
extension InventoryLine {
    var resource: Resource {
        switch self {
        case .l(let resource): resource
        case .e(let resource): resource
        case .x(let resource): resource
        case .o(let resource): resource
        }
    }
}
extension InventoryLine: ConvertibleToJSString, LoadableFromJSString {}
extension InventoryLine: CustomStringConvertible, LosslessStringConvertible {}
