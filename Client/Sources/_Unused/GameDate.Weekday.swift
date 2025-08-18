/*
extension GameDate {
    @frozen public enum Weekday: Int, Equatable, Hashable, Sendable {
        case sunday = 0
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }
}
extension GameDate.Weekday {
    @inlinable public func advanced(by stride: Int) -> Self {
        .init(rawValue: (self.rawValue + stride) % 7)!
    }
    /// Returns the number of days to the given weekday, modulo 7. The result is always in
    /// the range `0 ..< 7`.
    @inlinable public func distance(to that: Self) -> Int {
        let distance: Int = that.rawValue - self.rawValue
        return distance < 0 ? distance + 7 : distance
    }
}
extension GameDate.Weekday {
    /// Returns the three-letter abbreviation of the weekday in the given locale if supported,
    /// in English otherwise.
    @inlinable public func short(_ locale: Locale = .en_US) -> String {
        switch self {
        case .sunday:       "Sun"
        case .monday:       "Mon"
        case .tuesday:      "Tue"
        case .wednesday:    "Wed"
        case .thursday:     "Thu"
        case .friday:       "Fri"
        case .saturday:     "Sat"
        }
    }

    /// Returns the full name of the weekday in the given locale if supported, in English
    /// otherwise. If `capitalized` is true, the first letter of the name is capitalized.
    /// Otherwise, the capitalization follows the locale’s conventions.
    @inlinable public func long(
        _ locale: Locale = .en_US,
        capitalized: Bool = false
    ) -> String {
        switch self {
        case .sunday:       "Sunday"
        case .monday:       "Monday"
        case .tuesday:      "Tuesday"
        case .wednesday:    "Wednesday"
        case .thursday:     "Thursday"
        case .friday:       "Friday"
        case .saturday:     "Saturday"
        }
    }
}
*/
