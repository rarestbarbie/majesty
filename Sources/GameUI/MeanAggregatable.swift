public protocol MeanAggregatable<Fields> {
    associatedtype Fields
    var weighted: Fields { get }
    var weight: Double { get }
}
extension MeanAggregatable {
    @inlinable public var μ: Mean<Fields> {
        .init(fields: self.weighted, weight: self.weight)
    }
}
