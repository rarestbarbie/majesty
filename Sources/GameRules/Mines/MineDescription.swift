import GameIDs
import JavaScriptInterop
import JavaScriptKit

struct MineDescription {
    let miner: Symbol
    let decay: Bool
    let base: SymbolTable<Int64>
    let geology: SymbolTable<Int64>
    let initialSize: Int64
}
extension MineDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case miner
        case decay
        case base
        case geology
        case initial_size
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            miner: try js[.miner].decode(),
            decay: try js[.decay]?.decode() ?? true,
            base: try js[.base].decode(),
            geology: try js[.geology]?.decode() ?? [:],
            initialSize: try js[.initial_size].decode()
        )
    }
}
