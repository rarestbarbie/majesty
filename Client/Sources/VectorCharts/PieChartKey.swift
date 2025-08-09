public protocol PieChartKey: Identifiable<String> {
    associatedtype ShareFormat: DecimalFormat = DecimalFormat1F

    /// An identifier for the sector, which will be used as a CSS class name.
    override var id: String { get }
    /// A human-readable name for the sector.
    var name: String { get }
}
