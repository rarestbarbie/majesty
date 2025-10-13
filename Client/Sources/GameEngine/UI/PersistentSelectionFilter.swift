protocol PersistentSelectionFilter<Selection>: Hashable {
    associatedtype Selection

    static func ~= (self: Self, value: Selection) -> Bool
}
