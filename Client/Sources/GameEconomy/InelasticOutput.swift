@frozen public struct InelasticOutput {
    public let id: Resource

    @inlinable public init(id: Resource) {
        self.id = id
    }
}

#if TESTABLE
extension InelasticOutput: Equatable, Hashable {}
#endif
