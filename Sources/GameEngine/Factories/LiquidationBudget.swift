import JavaScriptInterop
import JavaScriptKit

struct LiquidationBudget {
    var buybacks: Int64

    init(buybacks: Int64 = 0) {
        self.buybacks = buybacks
    }
}
extension LiquidationBudget {
    enum ObjectKey: JSString, Sendable {
        case buybacks = "b"
    }
}
extension LiquidationBudget: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.buybacks] = self.buybacks
    }
}
extension LiquidationBudget: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            buybacks: try js[.buybacks].decode()
        )
    }
}
#if TESTABLE
extension LiquidationBudget: Equatable, Hashable {}
#endif
