extension PieChart {
    @frozen public struct Sector: Identifiable {
        public let id: Key
        public let value: Value
        public let slice: (share: Double, d: String)?

        @inlinable public init(id: Key, value: Value, slice: (share: Double, d: String)?) {
            self.id = id
            self.value = value
            self.slice = slice
        }
    }
}
extension PieChart.Sector {
    @inlinable public var share: Double? { self.slice?.share ?? 1 }
}
