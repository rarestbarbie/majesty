public protocol Turnable<Dimensions> {
    associatedtype Dimensions

    var yesterday: Dimensions { get set }
    var today: Dimensions { get }

    mutating func turn()
}
extension Turnable {
    @inlinable public mutating func turn() {}
}
