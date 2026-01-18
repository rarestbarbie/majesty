import GameIDs
import JavaScriptInterop

struct MineDescription {
    let miner: Symbol
    let decay: Bool
    let scale: Int64
    let spawn: SymbolTable<SpawnWeight>
    let base: SymbolTable<Int64>
}
extension MineDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case miner
        case decay
        case scale
        case spawn
        case base
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            miner: try js[.miner].decode(),
            decay: try js[.decay]?.decode() ?? true,
            scale: try js[.scale].decode(),
            spawn: try js[.spawn]?.decode() ?? [:],
            base: try js[.base].decode(),
        )
    }
}
