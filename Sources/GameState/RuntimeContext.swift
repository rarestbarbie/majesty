public protocol RuntimeContext<State>: ~Copyable {
    associatedtype Metadata: AnyObject
    associatedtype State: Identifiable where State.ID: Comparable & Sendable

    init(type: Metadata, state: State)

    var state: State { get set }
    var type: Metadata { get }
}
