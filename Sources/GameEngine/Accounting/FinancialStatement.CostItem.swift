import GameIDs
import JavaScriptInterop

extension FinancialStatement {
    @StringUnion @frozen public enum CostItem: Equatable, Hashable, Comparable {
        @tag("R") case resource(Resource)
        @tag("W") case workers
        @tag("C") case clerks
        // TODO: include wages, labor cost, etc.
    }
}
extension FinancialStatement.CostItem: LosslessStringConvertible {}
extension FinancialStatement.CostItem: ConvertibleToJSString, LoadableFromJSString {}
