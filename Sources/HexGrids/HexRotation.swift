@frozen public enum HexRotation {
    case cw
    case ccw
}
extension HexRotation {
    @inlinable public var inverted: Self {
        switch self {
        case .cw: .ccw
        case .ccw: .cw
        }
    }

    var angle: Double {
        switch self {
        case .cw: -.pi / 6.0
        case .ccw: .pi / 6.0
        }
    }
}
