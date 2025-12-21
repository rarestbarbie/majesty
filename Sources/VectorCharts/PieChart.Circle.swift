extension PieChart {
    @frozen public struct Circle {
        public let id: Key
        public let value: Value

        @inlinable init(id: Key, value: Value) {
            self.id = id
            self.value = value
        }
    }
}
extension PieChart.Circle: Sendable where Key: Sendable, Value: Sendable {}
