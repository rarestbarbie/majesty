import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct InfrastructureReportRequest {
    @usableFromInline let subject: BuildingID?
    @usableFromInline let details: BuildingDetailsTab?
    @usableFromInline let detailsTier: ResourceTierIdentifier?
    @usableFromInline let filter: InfrastructureReport.Filter?
}
extension InfrastructureReportRequest: QueryParameterDecodable {
    @frozen public enum QueryKey: JSString, Sendable {
        case subject = "id"
        case details
        case detailsTier
        case filter
    }

    public init(from js: borrowing QueryParameterDecoder<QueryKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            detailsTier: try js[.detailsTier]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
