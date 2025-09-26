import GameState
import JavaScriptInterop
import JavaScriptKit

struct EquitySplit {
    let code: Int64
    let date: GameDate
}
extension EquitySplit {
    static func reverse(factor: Int64, on date: GameDate) -> Self {
        .init(code: -factor, date: date)
    }

    static func forward(factor: Int64, on date: GameDate) -> Self {
        .init(code: factor, date: date)
    }

    var factor: Factor {
        self.code < 0 ? .reverse(-self.code) : .forward(self.code)
    }
}
extension EquitySplit {
    enum ObjectKey: JSString, Sendable {
        case code = "c"
        case date = "d"
    }
}
extension EquitySplit: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.code] = self.code
        js[.date] = self.date
    }
}
extension EquitySplit: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            code: try js[.code].decode(),
            date: try js[.date].decode()
        )
    }
}
#if TESTABLE
extension EquitySplit: Equatable, Hashable {}
#endif
