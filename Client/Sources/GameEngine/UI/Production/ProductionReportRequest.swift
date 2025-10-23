import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct ProductionReportRequest {
    @usableFromInline let subject: FactoryID?
    @usableFromInline let details: FactoryDetailsTab?
    @usableFromInline let filter: ProductionReport.Filter?
}
extension ProductionReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        // case column
        case filter
    }
}
extension ProductionReportRequest: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.subject] = self.subject
        js[.details] = self.details
        // js[.column] = self.column
        js[.filter] = self.filter
    }
}
extension ProductionReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            // column: try js[.column]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
