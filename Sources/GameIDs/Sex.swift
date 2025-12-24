import Bijection

@frozen public enum Sex: CaseIterable, Equatable, Hashable, Comparable, Sendable {
    case F
    case X
    case M
}
extension Sex: CustomStringConvertible {
    @inlinable public var description: String { .init(self.letter) }
}
extension Sex: LosslessStringConvertible {
    @Bijection(where: "StringProtocol") @inlinable public var letter: Unicode.Scalar {
        switch self {
        case .F: "F"
        case .X: "X"
        case .M: "M"
        }
    }
}
