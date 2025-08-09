/*
extension GameDate {
    @frozen public enum Month: Int32, Equatable, Hashable, Sendable, CaseIterable {
        case january = 1
        case february
        case march
        case april
        case may
        case june
        case july
        case august
        case september
        case october
        case november
        case december
    }
}
extension GameDate.Month {
    @inlinable public init?(number: Int32) { self.init(rawValue: number) }
    @inlinable public var number: Int32 { self.rawValue }
}
extension GameDate.Month {
    @inlinable public var predecessor: Self {
        switch self {
        case .january:      .december
        case .february:     .january
        case .march:        .february
        case .april:        .march
        case .may:          .april
        case .june:         .may
        case .july:         .june
        case .august:       .july
        case .september:    .august
        case .october:      .september
        case .november:     .october
        case .december:     .november
        }
    }
    @inlinable public var successor: Self {
        switch self {
        case .january:      .february
        case .february:     .march
        case .march:        .april
        case .april:        .may
        case .may:          .june
        case .june:         .july
        case .july:         .august
        case .august:       .september
        case .september:    .october
        case .october:      .november
        case .november:     .december
        case .december:     .january
        }
    }
}
extension GameDate.Month: LosslessStringConvertible {
    @inlinable public init?(_ description: some StringProtocol) {
        guard
        let rawValue: Int32 = .init(description) else {
            return nil
        }

        self.init(rawValue: rawValue)
    }
}
extension GameDate.Month:CustomStringConvertible {
    /// Formats the month without leading zeros.
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension GameDate.Month {
    /// Formats the month with two digits, zero-padded.
    @inlinable public var padded: String { self.rawValue < 10 ? "0\(self)" : "\(self)" }
}
extension GameDate.Month {
    @inlinable public func days(leap: Bool) -> ClosedRange<Int32> {
        switch self {
        case .january:      1 ... 31
        case .february:     leap ? 1 ... 29 : 1 ... 28
        case .march:        1 ... 31
        case .april:        1 ... 30
        case .may:          1 ... 31
        case .june:         1 ... 30
        case .july:         1 ... 31
        case .august:       1 ... 31
        case .september:    1 ... 30
        case .october:      1 ... 31
        case .november:     1 ... 30
        case .december:     1 ... 31
        }
    }
}
extension GameDate.Month {
    /// Returns the three-letter abbreviation of the month in English.
    @inlinable public
    var short: String {
        switch self {
        case .january:      "Jan"
        case .february:     "Feb"
        case .march:        "Mar"
        case .april:        "Apr"
        case .may:          "May"
        case .june:         "Jun"
        case .july:         "Jul"
        case .august:       "Aug"
        case .september:    "Sep"
        case .october:      "Oct"
        case .november:     "Nov"
        case .december:     "Dec"
        }
    }

    @inlinable public
    func long(_ locale: Locale = .en_US, capitalized: Bool = false) -> String {
        switch self {
        case .january:      "January"
        case .february:     "February"
        case .march:        "March"
        case .april:        "April"
        case .may:          "May"
        case .june:         "June"
        case .july:         "July"
        case .august:       "August"
        case .september:    "September"
        case .october:      "October"
        case .november:     "November"
        case .december:     "December"
        }
    }
}
*/
