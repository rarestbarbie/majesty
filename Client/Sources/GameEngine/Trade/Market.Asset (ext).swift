import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Market.Asset: ConvertibleToJSValue {
    public var jsValue: JSValue {
        .string(.init(self.code))
    }
}
extension Market.Asset: LoadableFromJSValue {
    public static func load(from js: JSValue) throws -> Self {
        guard case .string(let js) = js,
        let value: Self = .code(js.description) else {
            throw JavaScriptTypecastError<Self>.string(js.description)
        }
        return value
    }
}
