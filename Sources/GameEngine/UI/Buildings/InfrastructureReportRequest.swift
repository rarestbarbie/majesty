import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct InfrastructureReportRequest {
    @usableFromInline let subject: BuildingID?
    @usableFromInline let details: BuildingDetailsTab?
    @usableFromInline let detailsTier: ResourceTierIdentifier?
    @usableFromInline let filter: InfrastructureReport.Filter?
}
extension InfrastructureReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        case detailsTier
        case filter
    }
}
extension InfrastructureReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            detailsTier: try js[.detailsTier]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
