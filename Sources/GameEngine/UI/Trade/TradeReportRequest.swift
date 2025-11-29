import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TradeReportRequest {
    @usableFromInline let subject: WorldMarket.ID?
    @usableFromInline let filter: TradeReport.Filter?
}
extension TradeReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case filter
    }
}
extension TradeReportRequest: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.subject] = self.subject
        js[.filter] = self.filter
    }
}
extension TradeReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
