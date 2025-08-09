/// A type that can format a sector share as a percentage, without the percent sign.
public protocol DecimalFormat: ExpressibleByFloatLiteral, CustomStringConvertible {
    init(_ share: Double)

    /// Formats this share as a percentage, without the percent sign. Returns nil if
    /// the share is less than some custom-defined threshold.
    var formatted: String { get }
}
extension DecimalFormat {
    @inlinable public init(floatLiteral: Double) {
        self.init(floatLiteral)
    }

    /// Formats this share as a percentage, without the percent sign.
    @inlinable public var description: String { self.formatted }
}
