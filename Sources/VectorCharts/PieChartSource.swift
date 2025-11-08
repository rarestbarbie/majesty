import Vector

public protocol PieChartSource<Key, Sectors> {
    associatedtype Sectors: Sequence<(id: Key, value: Int64)>
    associatedtype Key: PieChartKey

    var sectors: Sectors { get }
}
