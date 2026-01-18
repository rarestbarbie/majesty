import GameIDs

extension EconomicLedger {
    enum Industry: Hashable {
        case building(BuildingType)
        case factory(FactoryType)
        case slavery(CultureID)
        case artisan(Resource)
    }
}
