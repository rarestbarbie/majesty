import Color
import JavaScriptInterop
import JavaScriptKit

struct TerrainDescription {
    let color: Color
}
extension TerrainDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode()
        )
    }
}
