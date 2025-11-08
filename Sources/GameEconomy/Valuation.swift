// @frozen public struct Valuation {
//     public var yesterday: Int64
//     public var today: Int64

//     @inlinable init(yesterday: Int64, today: Int64) {
//         self.yesterday = yesterday
//         self.today = today
//     }
// }
// extension Valuation {
//     @inlinable static var zero: Self { .init(yesterday: 0, today: 0) }
// }
// extension Valuation {
//     @inlinable mutating func turn() {
//         self.yesterday = self.today
//     }
// }
