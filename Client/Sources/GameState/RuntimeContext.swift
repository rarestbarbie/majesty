public protocol RuntimeContext<State> {
    associatedtype Metadata: AnyObject
    associatedtype State: Identifiable where State.ID: Comparable & Sendable

    init(type: Metadata, state: State)

    var state: State { get set }
}
