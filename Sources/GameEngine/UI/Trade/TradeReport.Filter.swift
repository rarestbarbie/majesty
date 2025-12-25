import GameEconomy
import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension TradeReport {
    @StringUnion @frozen public enum Filter: Equatable, Hashable, Comparable {
        @tag("A") case asset(WorldMarket.Asset)
    }
}
extension TradeReport.Filter: CustomStringConvertible, LosslessStringConvertible {}
extension TradeReport.Filter: ConvertibleToJSString, LoadableFromJSString {}
