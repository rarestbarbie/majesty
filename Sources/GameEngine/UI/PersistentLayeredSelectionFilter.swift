protocol PersistentLayeredSelectionFilter<Subject>: PersistentExclusiveSelectionFilter {
    associatedtype Layer

    static var all: Self { get }

    static func ~= (self: Self, value: Subject) -> Bool
    static func += (self: inout Self, layer: Layer)
}
