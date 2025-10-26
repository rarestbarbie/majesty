import GameIDs
import GameState
import JavaScriptInterop
import JavaScriptKit

@StringUnion enum MineType: Equatable, Hashable {
    @tag("P") case politician(Resource)
    @tag("M") case miner(Resource)
}
extension MineType {
    init(minerPop: PopType, resource: Resource) {
        switch minerPop {
        case .Politician: self = .politician(resource)
        case .Miner: self = .miner(resource)
        default: fatalError("Invalid pop type for MineType")
        }
    }
}
extension MineType: CustomStringConvertible, LosslessStringConvertible {}
extension MineType: ConvertibleToJSString, LoadableFromJSString {}
extension MineType {
    var resource: Resource {
        switch self {
        case .politician(let resource): resource
        case .miner(let resource): resource
        }
    }

    var minerPop: PopType {
        switch self {
        case .politician: .Politician
        case .miner: .Miner
        }
    }
}
