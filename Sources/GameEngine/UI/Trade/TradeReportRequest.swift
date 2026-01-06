import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TradeReportRequest {
    @usableFromInline let subject: WorldMarket.ID?
    @usableFromInline let filter: TradeReport.Filter?
}
extension TradeReportRequest: QueryParameterDecodable {
    @frozen public enum QueryKey: JSString, Sendable {
        case subject = "id"
        case filter
    }

    public init(from js: borrowing QueryParameterDecoder<QueryKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
