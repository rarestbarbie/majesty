import GameIDs
import JavaScriptKit
import JavaScriptInterop

@StringUnion @frozen public enum InventoryLine: Equatable, Hashable {
    @tag("l") case l(Resource)
    @tag("e") case e(Resource)
    @tag("x") case x(Resource)
    @tag("o") case o(Resource)
    @tag("m") case m(MineVein)
}
extension InventoryLine {
    var query: InventorySnapshot.Query {
        switch self {
        case .l(let id): .consumed(.l(id))
        case .e(let id): .consumed(.e(id))
        case .x(let id): .consumed(.x(id))
        case .o(let id): .produced(.o(id))
        case .m(let id): .produced(.m(id))
        }
    }

    var resource: Resource {
        switch self {
        case .l(let resource): resource
        case .e(let resource): resource
        case .x(let resource): resource
        case .o(let resource): resource
        case .m(let vein): vein.resource
        }
    }
}
extension InventoryLine: ConvertibleToJSString, LoadableFromJSString {}
extension InventoryLine: CustomStringConvertible, LosslessStringConvertible {}
