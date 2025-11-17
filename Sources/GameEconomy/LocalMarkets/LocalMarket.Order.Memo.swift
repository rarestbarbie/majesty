import GameIDs

extension LocalMarket.Order {
    @frozen public enum Memo {
        case mine(MineID)
        case tier(UInt8)
    }
}
