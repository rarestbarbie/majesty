import GameIDs

extension LocalMarket {
    @frozen public enum Memo {
        case mine(MineID)
        case tier(UInt8)
    }
}
