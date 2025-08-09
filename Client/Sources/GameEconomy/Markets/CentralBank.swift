struct CentralBank {
    let id: Fiat
    /// The balance of the central bank in its own currency.
    ///
    /// This is always a negative number, because the central bank is the issuer of the
    /// currency. The magnitude of the balance is the amount of currency in circulation.
    var balance: Int
    /// The amount of foreign currency held by the central bank. When foreign currency is
    /// deposited at the central bank, it prints and issues its own currency in exchange.
    ///
    /// If a foreigner has a persistent trade deficit with the central bank’s host, their
    /// currency will accumulate in the central bank’s reserve, which reduces the amount of
    /// the foreign central bank’s currency in circulation and increases the amount of the
    /// local central bank’s currency in circulation.
    ///
    /// Over time, the foreign currency becomes scarcer and the central bank’s currency will
    /// become more abundant, excluding the reserves of the banks themselves. This won’t
    /// necessarily lead to a change in the exchange rate, because the foreign central bank
    /// is probably doing the same thing. However, the total amount of currency (of both
    /// types) in circulation will grow, causing inflation.
    ///
    /// This looks slightly different from the perspective of both countries.
    ///
    /// -   In the host country, inflation occurs because the local producers have
    ///     accumulated earnings, which is denominated in the local currency, but backed
    ///     (through the central bank’s reserves) by foreign currency.
    ///
    /// -   In the foreign country, inflation occurs because its central bank is, directly
    ///     or indirectly, printing more of its own currency so its citizens can exchange it
    ///     for the host country’s currency.
    ///
    /// In the game, players with robust trading relationships will accumulate large
    /// balances in each other’s central banks, which can be weaponized if the
    /// relationship deteriorates. Players might choose to “buy back” their own currency
    /// in exchange for their own reserve of the other player’s currency. Alternatively,
    /// they can just ignore the problem until it mushrooms into a crisis.
    ///
    /// It’s important to remember that the foreign country can always sieze the reserves
    /// of the host country’s central bank, because the foreign central bank decides what
    /// the foreign currency is worth. In other words, these values are not amounts stored
    /// in the central bank’s “vaults”, but rather its own bank accounts located in foreign
    /// central banks.
    ///
    /// No central bank is obligated to hold any foreign reserves at all – an isolationist
    /// player might choose to outlaw all foreign accounts entirely. However, holding
    /// foreign reserves allows players with low Central Bank Legitimacy to claim some of
    /// the Legitimacy of a foreign central bank as their own.
    ///
    /// By default, the amount of foreign currency another player can sell to the central
    /// bank is capped. However, players can extend Liquidity Swaps to each other, allowing
    /// the other player to sell an unlimited amount of their currency to the central bank.
    /// A Liquidity Swap signifies deep diplomatic trust, as it functionally offers the
    /// other player a blank check to withdraw an infinite amount of the player’s own
    /// currency.
    var reserve: [Fiat: Int]

    init(id: Fiat) {
        self.id = id
        self.balance = 0
        self.reserve = [:]
    }
}
