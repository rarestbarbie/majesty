import GameState

extension GameContext {
    struct ResidentOrder {
        let residents: [Resident]
    }
}
extension GameContext.ResidentOrder {
    // cannot use parameter packs due to some compiler bug
    static func randomize<C1, C2, C3>(
        _ c1: (DynamicContextTable<C1>, (Int) -> GameContext.Resident),
        _ c2: (DynamicContextTable<C2>, (Int) -> GameContext.Resident),
        _ c3: (DynamicContextTable<C3>, (Int) -> GameContext.Resident),
        with random: inout some RandomNumberGenerator
    ) -> Self where C1: ~Copyable, C2: ~Copyable, C3: ~Copyable {
        var residents: [GameContext.Resident] = []
        residents.reserveCapacity(
            c1.0.count +
            c2.0.count +
            c3.0.count
        )

        for index: Int in c1.0.indices {
            residents.append(c1.1(index))
        }
        for index: Int in c2.0.indices {
            residents.append(c2.1(index))
        }
        for index: Int in c3.0.indices {
            residents.append(c3.1(index))
        }

        residents.shuffle(using: &random)

        return .init(residents: residents)
    }
}
