import GameState

extension GameContext {
    struct ResidentOrder {
        let residents: [Resident]
    }
}
extension GameContext.ResidentOrder {
    static func randomize<each Context>(
        _ context: repeat (DynamicContextTable<each Context>, (Int) -> GameContext.Resident),
        with random: inout some RandomNumberGenerator
    ) -> Self {
        var residents: [GameContext.Resident] = []
        var count: Int = 0
        for (table, _): (_, (Int) -> GameContext.Resident) in repeat each context {
            count += table.count
        }

        residents.reserveCapacity(count)

        for (table, id): (_, (Int) -> GameContext.Resident) in repeat each context {
            for index: Int in table.indices {
                residents.append(id(index))
            }
        }

        residents.shuffle(using: &random)

        return .init(residents: residents)
    }
}
