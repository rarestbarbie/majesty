import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension BlocMarket.Asset: ConvertibleToJSValue {
    public var jsValue: JSValue {
        .string(.init(self.code))
    }
}
extension BlocMarket.Asset: LoadableFromJSValue {
    public static func load(from js: JSValue) throws -> Self {
        guard case .string(let js) = js,
        let value: Self = .code(js.description) else {
            throw JavaScriptTypecastError<Self>.string(js.description)
        }
        return value
    }
}
