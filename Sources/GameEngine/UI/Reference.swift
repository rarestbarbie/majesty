public final class Reference<Value>: Sendable where Value: ~Copyable & Sendable {
    public let value: Value

    @inlinable public init(value: consuming Value) {
        self.value = value
    }
}
