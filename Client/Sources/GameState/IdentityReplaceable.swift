public protocol IdentityReplaceable<ID>: Identifiable {
    var id: ID { get set }
}
