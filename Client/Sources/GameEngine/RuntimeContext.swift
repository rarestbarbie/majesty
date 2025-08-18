import JavaScriptKit
import JavaScriptInterop

protocol RuntimeContext<State> {
    associatedtype Metadata: AnyObject
    associatedtype State: Identifiable where State.ID: Comparable & Sendable
    associatedtype Pass

    init(type: Metadata, state: State)

    var state: State { get set }

    mutating func compute(in pass: Pass) throws
    mutating func advance(in context: GameContext, on map: inout GameMap) throws
}
extension RuntimeContext where State: Turnable {
    mutating func turn() {
        { $0.yesterday = $0.today ; $0.turn() } (&self.state)
    }
}
