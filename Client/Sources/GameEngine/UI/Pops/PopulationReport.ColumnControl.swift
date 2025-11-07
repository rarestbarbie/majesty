import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension PopulationReport {
    @StringUnion @frozen @usableFromInline enum ColumnControl {
        @tag("T") case type(PopType)
        @tag("R") case race(String)
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
            return Self.order(a.type, b.type, around: first).map(!)
        case .race(let first):
            return Self.order(a.nat, b.nat, around: first)
        }
    }

    private static func order<Key>(_ a: Key, _ b: Key, around pivot: Key) -> Bool?
        where Key: Comparable {
        if  a == b {
            return nil
        }
        switch (a < pivot, b < pivot) {
        case (false, true):
            return true
        case (true, false):
            return false
        default:
            return a < b
        }
    }
}
