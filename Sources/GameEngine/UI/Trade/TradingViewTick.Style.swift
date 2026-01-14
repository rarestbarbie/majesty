extension TradingViewTick {
    enum Style {
        case price
        case grid
    }
}
extension TradingViewTick.Style {
    var id: String {
        switch self {
        case .price: "price"
        case .grid: "grid"
        }
    }
}
