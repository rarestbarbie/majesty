@frozen public struct ColorText: Equatable, Sendable {
    @usableFromInline var buffer: String

    @inlinable public init(buffer: String) {
        self.buffer = buffer
    }
}

extension ColorText {
    @inlinable public var html: String { self.buffer }
}
extension ColorText: ExpressibleByStringLiteral {
    @inlinable public init(stringLiteral: String) {
        self.init(buffer: stringLiteral)
    }
}
extension ColorText: ExpressibleByStringInterpolation {
    @inlinable public init(stringInterpolation: Self) {
        self = stringInterpolation
    }
}
extension ColorText: StringInterpolationProtocol {
    @inlinable public init(literalCapacity: Int, interpolationCount: Int) {
        self.buffer = ""
        self.buffer.reserveCapacity(literalCapacity)
    }

    @inlinable public mutating func appendLiteral(_ literal: String) {
        self.buffer.append(literal)
    }

    @available(*, deprecated,
        message: """
        ColorText interpolation of 'Double' may produce a very long sequence of digits – \
        did you mean to use '[..places]' instead?
        """
    )
    @inlinable public mutating func appendInterpolation(_ value: Double) {
        self.buffer.append("\(value)")
    }
    @available(*, deprecated,
        message: """
        ColorText interpolation of 'Decimal' produces a debug string, not a formatted one – \
        did you mean to use '[..]' instead?
        """
    )
    @inlinable public mutating func appendInterpolation(_ value: Decimal) {
        self.buffer.append("\(value)")
    }

    @inlinable public mutating func appendInterpolation(_ value: some CustomStringConvertible) {
        self.buffer.append(value.description)
    }

    @inlinable public mutating func appendInterpolation(em value: some CustomStringConvertible) {
        self.buffer.append("<em>\(value)</em>")
    }

    @inlinable public mutating func appendInterpolation(pos value: some CustomStringConvertible) {
        self.buffer.append("<ins>\(value)</ins>")
    }

    @inlinable public mutating func appendInterpolation(neg value: some CustomStringConvertible) {
        self.buffer.append("<del>\(value)</del>")
    }
}
