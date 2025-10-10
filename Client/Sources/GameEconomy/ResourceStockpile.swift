import GameIDs

public protocol ResourceStockpile: Identifiable<Resource> {
    init(id: Resource)
}
