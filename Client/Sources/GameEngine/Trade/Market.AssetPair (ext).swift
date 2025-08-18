import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

extension Market.AssetPair: ConvertibleToJSValue {
    public var jsValue: JSValue {
        .string(.init(self.code))
    }
}
extension Market.AssetPair: LoadableFromJSValue {
    public static func load(from js: JSValue) throws -> Self {
        guard case .string(let js) = js,
        let value: Self = .code(js.description) else {
            throw JavaScriptTypecastError<Self>.string(js.description)
        }
        return value
    }
}
// extension Market.Pair {
//     public enum ObjectKey: JSString, Sendable {
//         case xfiat
//         case xgood

//         case yfiat
//         case ygood
//     }
// }
// extension Market.Pair: JavaScriptEncodable {

//     public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
//         switch self.x {
//         case .fiat(let x):
//             js[.xfiat] = x
//         case .good(let x):
//             js[.xgood] = x
//         }

//         switch self.y {
//         case .fiat(let y):
//             js[.yfiat] = y
//         case .good(let y):
//             js[.ygood] = y
//         }
//     }
// }
// extension Market.Pair: JavaScriptDecodable {
//     public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
//         if  let xfiat: Resource.Fiat = try js[.xfiat]?.decode() {
//             if  let yfiat: Resource.Fiat = try js[.yfiat]?.decode() {
//                 self.init(.fiat(xfiat), .fiat(yfiat))
//             } else {
//                 self.init(.fiat(xfiat), .good(try js[.ygood].decode()))
//             }
//         } else {
//             let xgood: Resource = try js[.xgood].decode()
//             if  let yfiat: Resource.Fiat = try js[.yfiat]?.decode() {
//                 self.init(.good(xgood), .fiat(yfiat))
//             } else {
//                 self.init(.good(xgood), .good(try js[.ygood].decode()))
//             }
//         }

//     }
// }
