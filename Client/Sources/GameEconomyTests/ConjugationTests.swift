import GameEconomy
import Testing

@Suite struct ConjugationTests {
    @Test static func Symmetry() throws {
        var exchange: Exchange = .init()
        let UNB: Fiat = 0
        let MAR: Fiat = 1

        exchange[MAR / UNB].liq = (base: 1, quote: 4)

        // Test read accessor
        #expect(exchange[MAR / UNB].liq == (1, 4))
        #expect(exchange[UNB / MAR].liq == (4, 1))

        // Test modify accessor
        #expect({ $0.liq } (&exchange[MAR / UNB]) == (1, 4))
        #expect({ $0.liq } (&exchange[UNB / MAR]) == (4, 1))
    }
}
