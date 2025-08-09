import JavaScriptKit
import JavaScriptInterop
import Vector

extension Vector3: ConvertibleToJSArray {
    @inlinable public func encode(to js: inout JavaScriptEncoder<JavaScriptArrayKey>) {
        js[0] = self.x
        js[1] = self.y
        js[2] = self.z
    }
}
extension Vector3: LoadableFromJSArray {
    @inlinable public static func load(
        from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Self {
        .init(
            try js[0].decode(),
            try js[1].decode(),
            try js[2].decode()
        )
    }
}
