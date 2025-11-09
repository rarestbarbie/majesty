@frozen public struct GameDate: RawRepresentable, Equatable, Hashable, Sendable {
    /// Number of days since Year 0, whatever that means.
    public var rawValue: Int32

    @inlinable public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}
extension GameDate {
    @inlinable public static var min: Self { .init(rawValue: .min) }
    @inlinable public static var max: Self { .init(rawValue: .max) }
}
extension GameDate: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}
extension GameDate {
    @inlinable public mutating func increment() {
        self.rawValue += 1
    }

    @inlinable public mutating func advance(by days: Int) {
        self.rawValue += Int32.init(days)
    }

    @inlinable public consuming func advanced(by days: Int) -> Self {
        self.advance(by: days)
        return self
    }
}
// Algorithm from "Calendrical Calculations" by Dershowitz and Reingold
extension GameDate {
    /// Converts a number of days since 0000-01-01 to a Gregorian date
    public var gregorian: (year: Int32, month: Int32, day: Int32) {
        let J: Int32 = self.rawValue + 1721425 // Julian day for 0000-01-01 is 1721425
        let j: Int32 = J + 32044

        let g: (quotient: Int32, remainder: Int32) = j.quotientAndRemainder(dividingBy: 146097)

        let c: Int32 = (g.remainder / 36524 + 1) * 3 / 4
        let dc: Int32 = g.remainder - c * 36524

        let b: (quotient: Int32, remainder: Int32) = dc.quotientAndRemainder(dividingBy: 1461)

        let a: Int32 = (b.remainder / 365 + 1) * 3 / 4
        let da: Int32 = b.remainder - a * 365

        let y: Int32 = g.quotient * 400 + c * 100 + b.quotient * 4 + a
        let m: Int32 = (da * 5 + 308) / 153 - 2
        let d: Int32 = da - (m + 4) * 153 / 5 + 122

        return (year: y - 4800 + (m + 2) / 12, month: (m + 2) % 12 + 1, day: d + 1)
    }

    /// Converts a Gregorian date to the number of days since 0000-01-01
    public static func gregorian(year: Int32, month: Int32, day: Int32) -> Self {
        // Algorithm from "Calendrical Calculations" by Dershowitz and Reingold
        let y: Int32 = year + 4800 - (14 - month) / 12
        let m: Int32 = month + 12 * ((14 - month) / 12) - 3
        let d: Int32 = day
        let J: Int32 = d + ((153 * m + 2) / 5) + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        // Days since 0000-01-01 is J - 1721425
        return .init(rawValue: J - 1721425)
    }
}
extension GameDate {
    @inlinable public subscript(format: GameDateFormat) -> String {
        switch format {
        case .phrasal_US:
            let (y, m, d): (Int32, Int32, Int32) = self.gregorian
            return "\(Month[m]) \(d), \(y)"

        case .phrasal_EU:
            let (y, m, d): (Int32, Int32, Int32) = self.gregorian
            return "\(d) \(Month[m]) \(y)"
        }
    }
}
