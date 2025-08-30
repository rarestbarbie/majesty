public protocol RuntimeContext<State> {
    associatedtype Metadata: AnyObject
    associatedtype State: Identifiable where State.ID: Comparable & Sendable
    associatedtype Pass

    init(type: Metadata, state: State)

    var state: State { get set }

    mutating func compute(in pass: Pass) throws
}
