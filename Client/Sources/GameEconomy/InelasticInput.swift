@frozen public struct InelasticInput: ResourceStockpile {
    public let id: Resource

    @inlinable public init(id: Resource) {
        self.id = id
    }
}
extension InelasticInput: ResourceInput {
    @inlinable public var consumedValue: Int64 { 0 }
}

#if TESTABLE
extension InelasticInput: Equatable, Hashable {}
#endif
