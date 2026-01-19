import JavaScriptInterop
import GameIDs

struct FactoryLiquidation {
    let started: GameDate
    /// The number of shares that needed to be liquidated.
    let burning: Int64
}
extension FactoryLiquidation {
    enum ObjectKey: JSString, Sendable {
        case started
        case burning
    }
}
extension FactoryLiquidation: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.started] = self.started
        js[.burning] = self.burning
    }
}
extension FactoryLiquidation: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            started: try js[.started].decode(),
            burning: try js[.burning].decode()
        )
    }
}

#if TESTABLE
extension FactoryLiquidation: Equatable, Hashable {}
#endif
