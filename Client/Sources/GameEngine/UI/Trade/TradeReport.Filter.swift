import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension TradeReport {
    @frozen public struct Filter: RawRepresentable, Equatable, Hashable {
        public let rawValue: Market.Asset
        @inlinable public init(rawValue: Market.Asset) {
            self.rawValue = rawValue
        }
    }
}
extension TradeReport.Filter: ConvertibleToJSValue, LoadableFromJSValue {}
extension TradeReport.Filter: PersistentSelectionFilter {
    typealias Subject = Market
    static func ~= (self: Self, value: Market) -> Bool {
        self.rawValue == value.id.x || self.rawValue == value.id.y
    }
}
