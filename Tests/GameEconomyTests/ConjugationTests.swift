import GameEconomy
import GameIDs
import Testing

@Suite struct ConjugationTests {
    @Test static func Symmetry() throws {
        var exchange: WorldMarkets = .init()
        let UNB: CurrencyID = 0
        let MAR: CurrencyID = 1

        exchange[MAR / UNB].assets = .init(base: 1, quote: 4)

        // Test read accessor
        #expect(exchange[MAR / UNB].assets == (1, 4))
        #expect(exchange[UNB / MAR].assets == (4, 1))

        // Test modify accessor
        #expect({ $0.assets } (&exchange[MAR / UNB]) == (1, 4))
        #expect({ $0.assets } (&exchange[UNB / MAR]) == (4, 1))
    }
}
