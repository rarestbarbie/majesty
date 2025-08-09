@frozen public struct Color: Equatable, Hashable, Sendable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8

    @inlinable public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}
extension Color: ExpressibleByIntegerLiteral {
    @inlinable public init(integerLiteral value: UInt32) {
        self = .hex(value)
    }
}
extension Color {
    @inlinable public static func hex(_ value: some FixedWidthInteger) -> Self {
        .init(
            r: UInt8.init(value >> 16 & 0xFF),
            g: UInt8.init(value >> 8 & 0xFF),
            b: UInt8.init(value & 0xFF)
        )
    }

    @inlinable public var hex: Int32 {
        Int32.init(self.r) << 16 |
        Int32.init(self.g) << 8 |
        Int32.init(self.b)
    }
}
