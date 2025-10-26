import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct ProductionReportRequest {
    @usableFromInline let subject: FactoryID?
    @usableFromInline let details: FactoryDetailsTab?
    @usableFromInline let detailsTier: ResourceTierIdentifier?
    @usableFromInline let filter: ProductionReport.Filter?
}
extension ProductionReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        case detailsTier
        // case column
        case filter
    }
}
extension ProductionReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            detailsTier: try js[.detailsTier]?.decode(),
            // column: try js[.column]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
