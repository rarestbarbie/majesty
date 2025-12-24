protocol PersistentSelectionFilter<Subject>: Hashable {
    associatedtype Subject: Identifiable
    associatedtype Layer

    static func += (self: inout Self, layer: Layer)
    static func ~= (self: Self, value: Subject) -> Bool
    static var all: Self { get }
}
