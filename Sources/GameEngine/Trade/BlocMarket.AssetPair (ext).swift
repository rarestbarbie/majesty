import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

extension BlocMarket.AssetPair: ConvertibleToJSValue {
    public var jsValue: JSValue {
        .string(.init(self.code))
    }
}
extension BlocMarket.AssetPair: LoadableFromJSValue {
    public static func load(from js: JSValue) throws -> Self {
        guard case .string(let js) = js,
        let value: Self = .code(js.description) else {
            throw JavaScriptTypecastError<Self>.string(js.description)
        }
        return value
    }
}
