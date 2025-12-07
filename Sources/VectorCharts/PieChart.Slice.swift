import Vector

extension PieChart {
    @frozen public struct Slice {
        public let id: Key
        public let value: Value
        @usableFromInline let geometry: Vector2.ArcGeometry

        @inlinable init(id: Key, value: Value, geometry: Vector2.ArcGeometry) {
            self.id = id
            self.value = value
            self.geometry = geometry
        }
    }
}
extension PieChart.Slice: Sendable where Key: Sendable, Value: Sendable {}
extension PieChart.Slice {
    @inlinable public var share: Double { self.geometry.share }
    @inlinable public var path: String { self.geometry.d }
}
