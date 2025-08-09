@_spi(testable)
import GameEconomy
import Testing

@Suite struct ArbitrageTests {
    @Test static func trade() throws {
        var exchange: Exchange = .init()

        let XAU: Resource = .init(rawValue: 1)
        /// United Nations Bancor
        let UNB: Fiat = 0
        /// Martian Rand
        let MAR: Fiat = 1

        /// Sell 1,000 XAU into the local Martian market. By default, markets start out with
        /// 2 units of liquidity on both sides, and there is no external demand for XAU yet,
        /// so only 2 units of XAU can be sold, and only 1 unit of MAR can be withdrawn.
        var xau: Int64 = 1_000
        #expect(exchange[XAU / MAR].sell(&xau) == 1)
        #expect(xau == 998)

        /// Spend 10,000 UNB to buy XAU from the Earth market. Since there is no supply yet,
        /// only one unit can be withdrawn, at a cost of 2 UNB.
        var unb: Int64 = 10_000
        #expect(exchange[XAU / UNB].buy(.max, with: &unb) == 1)
        #expect(unb == 9_998)

        /// There should be an excess of XAU in the Martian market, and an excess of UNB in the
        /// Earth market.
        #expect(exchange[XAU / MAR].liq == (base: 4, quote: 1))
        #expect(exchange[XAU / MAR].vol.base == (i: 2, o: 0))
        #expect(exchange[XAU / MAR].vol.quote == (i: 0, o: 1))

        #expect(exchange[XAU / UNB].liq == (base: 1, quote: 4))
        #expect(exchange[XAU / UNB].vol.base == (i: 0, o: 1))
        #expect(exchange[XAU / UNB].vol.quote == (i: 2, o: 0))

        /// Stake the remaining resources in their respective markets.
        _ = exchange[XAU / MAR].stake(xau)
        _ = exchange[UNB / XAU].stake(unb)

        exchange[XAU / MAR].vol = ((0, 0), (0, 0))
        exchange[UNB / XAU].vol = ((0, 0), (0, 0))

        /// There should be an excess of 1,000 XAU in the Martian market, and an excess of
        /// 10,000 UNB in the Earth market.
        #expect(exchange[XAU / MAR].liq == (base: 1_002, quote: 1))
        #expect(exchange[XAU / UNB].liq == (base: 1, quote: 10_002))

        var capital: Int64 = 10

        /// Arbitrage should fail, because the forex market is not liquid enough.
        #expect(nil == exchange.arbitrate(
            resource: XAU,
            currency: MAR,
            partners: [UNB],
            capital: &capital
        ))
        #expect(capital == 10)

        /// Inject 100 units of liquidity into the forex market on both sides.
        exchange[MAR / UNB] = .init(liq: (base: 100, quote: 100))

        let arbitrage: ResourceArbitrage = try #require(exchange.arbitrate(
            resource: XAU,
            currency: MAR,
            partners: [UNB],
            capital: &capital
        ))

        #expect(arbitrage.exported == 98)
        #expect(arbitrage.proceeds == 99)
        #expect(arbitrage.currency == UNB)

        /// Some of the Martian gold should have left Mars. Its local price should be higher
        /// than it was before.
        #expect(exchange[XAU / MAR].liq == (base: 904, quote: 2))
        #expect(exchange[XAU / MAR].vol.base == (i: 0, o: 98))
        #expect(exchange[XAU / MAR].vol.quote == (i: 1, o: 0))
        /// Most of the UNB should have left Earth, and been used to import the Martian gold.
        /// The local price of gold should be lower than it was before.
        #expect(exchange[XAU / UNB].liq == (base: 99, quote: 102))
        #expect(exchange[XAU / UNB].vol.base == (i: 98, o: 0))
        #expect(exchange[XAU / UNB].vol.quote == (i: 0, o: 9_900))
        /// The Martian Rand should have strengthened against the UNB.
        #expect(exchange[MAR / UNB].liq == (base: 1, quote: 10_000))
        #expect(exchange[MAR / UNB].vol.base == (i: 0, o: 99))
        #expect(exchange[MAR / UNB].vol.quote == (i: 9900, o: 0))

        /// The trader should have made a sizable profit from the exchange.
        #expect(capital == 108)
    }

    @Test static func forex() throws {
        var exchange: Exchange = .init()

        /// United Nations Bancor
        let UNB: Fiat = 0
        /// Martian Rand
        let MAR: Fiat = 1
        /// Lunar Bancor
        let LUB: Fiat = 2
        /// Ceres Reserve Note
        let CRN: Fiat = 3

        /// In this scenario, the Martian Rand and the United Nations Bancor have a “natural”
        /// exchange rate that values the Bancor much more than the Rand. However, there are two
        /// other currencies, LUB and CRN, that are artificially pegged to both the Martian Rand
        /// and the United Nations Bancor.
        exchange[MAR / UNB] = .init(liq: (base: 1000, quote: 100))
        exchange[LUB / UNB] = .init(liq: (base: 100, quote: 100))
        exchange[CRN / UNB] = .init(liq: (base: 50, quote: 50))

        exchange[LUB / MAR] = .init(liq: (base: 100, quote: 100))
        exchange[CRN / MAR] = .init(liq: (base: 100, quote: 100))

        exchange[CRN / LUB] = .init(liq: (base: 100, quote: 100))

        /// In this example, the arbitrageur buys Martian Rand with United Nations Bancor, and
        /// should decide to turn Martian Rand into Lunar Bancor using its 1:1 exchange rate.
        /// Since the Lunar Bancor can also be turned back into United Nations Bancor at a 1:1
        /// exchange rate, the arbitrageur end up with much more UNB than they started with.
        var capital: Int64 = 5
        let arbitrage: ResourceArbitrage = try #require(exchange.arbitrate(
            resource: .fiat(MAR),
            currency: UNB,
            partners: [LUB, CRN],
            capital: &capital
        ))

        /// In an infinitely liquid market, the arbitrageur would profited tenfold, but since
        /// the three markets have finite liquidity, the actual profit is lower.
        #expect(capital == 23)
        /// Although a similar arbitrage opportunity exists with the Ceres Reserve Note,
        /// the arbitrageur should have chosen the Lunar Bancor, since it is more profitable.
        /// It is more profitable because the LUB/UNB market is more liquid than the CRN/UNB
        /// market, so it would experience less slippage.
        #expect(arbitrage.currency == LUB)

        /// The Martian Rand should have appreciated against the United Nations Bancor,
        /// since it had been pegged to the Lunar Bancor, which itself had been pegged to the
        /// United Nations Bancor.
        #expect(exchange[MAR / UNB].liq == (base: 957, quote: 105))
        /// The Lunar Bancor should have depreciated against the United Nations Bancor,
        /// since it had been pegged to the Martian Rand, which was worth much less than the
        /// United Nations Bancor.
        #expect(exchange[LUB / UNB].liq == (base: 130, quote: 77))
        /// The Lunar Bancor should have appreciated against the Martian Rand, since it had
        /// been pegged to the United Nations Bancor, which was worth much more than the
        /// Martian Rand.
        #expect(exchange[LUB / MAR].liq == (base: 70, quote: 143))

        /// The Ceres Reserve Note should be unaffected, since it was not involved in the
        /// arbitrage.
        #expect(exchange[CRN / UNB].liq == (base: 50, quote: 50))
        #expect(exchange[CRN / MAR].liq == (base: 100, quote: 100))
        #expect(exchange[CRN / LUB].liq == (base: 100, quote: 100))
    }
}
