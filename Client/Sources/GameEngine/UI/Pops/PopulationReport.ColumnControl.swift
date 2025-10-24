import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension PopulationReport {
    @StringUnion @frozen @usableFromInline enum ColumnControl {
        @tag("T") case type(PopType)
    }
}
extension PopulationReport.ColumnControl: CustomStringConvertible, LosslessStringConvertible {}
extension PopulationReport.ColumnControl: ConvertibleToJSString, LoadableFromJSString {}
extension PopulationReport.ColumnControl: Identifiable {
    @inlinable var id: PopulationReport.ColumnControlType { self.type }
}
extension PopulationReport.ColumnControl {
    func ascending(_ a: PopTableEntry, _ b: PopTableEntry) -> Bool? {
        switch self {
        case .type(let first):
            if  a.type == b.type {
                return nil
            }
            switch (a.type < first, b.type < first) {
            case (false, true):
                return true
            case (true, false):
                return false
            default:
                return a.type < b.type
            }
        }
    }
}
