/// A type that can format a sector share with one decimal place.
@frozen public struct DecimalFormat1F {
    public let share: Double

    @inlinable public init(
        _ share: Double
    ) {
        self.share = share
    }
}
extension DecimalFormat1F: DecimalFormat {
    /// Formats the share as a percentage with one decimal place, without the percent sign.
    /// Returns nil if the share is less than 0.1 percent.
    public var formatted: String {
        guard self.share >= 0.1
        else {
            return "<0.1"
        }

        let permille: Int = .init((self.share * 1000).rounded())
        let (percent, f): (Int, Int) = permille.quotientAndRemainder(
            dividingBy: 10
        )

        return "\(percent).\(f)"
    }
}
