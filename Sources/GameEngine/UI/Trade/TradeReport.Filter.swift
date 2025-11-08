import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension TradeReport {
    @frozen public struct Filter: RawRepresentable, Equatable, Hashable {
        public let rawValue: BlocMarket.Asset
        @inlinable public init(rawValue: BlocMarket.Asset) {
            self.rawValue = rawValue
        }
    }
}
extension TradeReport.Filter: ConvertibleToJSValue, LoadableFromJSValue {}
extension TradeReport.Filter: PersistentSelectionFilter {
    typealias Subject = BlocMarket
    static func ~= (self: Self, value: BlocMarket) -> Bool {
        self.rawValue == value.id.x || self.rawValue == value.id.y
    }
}
