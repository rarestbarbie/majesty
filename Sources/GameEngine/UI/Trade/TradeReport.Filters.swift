import GameEconomy
import JavaScriptInterop

extension TradeReport {
    struct Filters: Equatable, Hashable {
        var asset: WorldMarket.Asset?
    }
}
extension TradeReport.Filters: PersistentLayeredSelectionFilter {
    typealias Subject = WorldMarket
    typealias Layer = TradeReport.Filter

    static var all: Self {
        .init(asset: nil)
    }
    static func += (self: inout Self, layer: TradeReport.Filter) {
        switch layer {
        case .asset(let asset):
            self.asset = asset
        }
    }
    static func ~= (self: Self, value: WorldMarket) -> Bool {
        if  let asset: WorldMarket.Asset = self.asset,
                asset != value.id.x,
                asset != value.id.y {
            return false
        }

        return true
    }
}
