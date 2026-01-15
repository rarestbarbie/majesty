import Color
import GameIDs

@frozen public struct EcologicalAttributes: Symbolizable, Equatable, Hashable {
    public typealias ID = EcologicalType
    public let identity: SymbolAssignment<EcologicalType>
    public let color: Color

    init(identity: SymbolAssignment<EcologicalType>, color: Color) {
        self.identity = identity
        self.color = color
    }
}
extension EcologicalAttributes {
    @inlinable public var title: String {
        self.identity.symbol.name
    }
}
