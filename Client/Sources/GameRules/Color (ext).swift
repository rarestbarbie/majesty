import GameEngine
import JavaScriptInterop
import JavaScriptKit

// JavaScript `number` is backed by double precision floating point, which can represent
// integers up to 2^53 - 1 exactly.
extension Color: ConvertibleToJSValue {
    @inlinable public var jsValue: JSValue {
        .number(Double.init(self.hex))
    }
}
extension Color: LoadableFromJSValue {
    public static func load(from value: JSValue) throws -> Self {
        // For ease of modding, we also allow hex strings.
        guard case .string(let string) = value else {
            return .hex(try Int32.load(from: value))
        }

        let color: String = string.description

        guard let i: String.Index = color.indices.first, case "#" = color[i] else {
            throw ColorParsingError.unknown(color)
        }

        guard let hex: UInt32 = .init(color[color.index(after: i)...], radix: 16) else {
            throw ColorParsingError.hex(color)
        }

        return .hex(hex)
    }
}
