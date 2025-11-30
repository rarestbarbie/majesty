import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension TradeReport {
    @frozen public struct Filter: RawRepresentable, Equatable, Hashable {
        public let rawValue: WorldMarket.Asset
        @inlinable public init(rawValue: WorldMarket.Asset) {
            self.rawValue = rawValue
        }
    }
}
extension TradeReport.Filter: ConvertibleToJSValue, LoadableFromJSValue {}
extension TradeReport.Filter: PersistentSelectionFilter {
    typealias Subject = WorldMarket
    static func ~= (self: Self, value: WorldMarket) -> Bool {
        self.rawValue == value.id.x || self.rawValue == value.id.y
    }
}
