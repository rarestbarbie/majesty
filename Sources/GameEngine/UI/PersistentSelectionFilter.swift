protocol PersistentSelectionFilter<Subject>: Hashable {
    associatedtype Subject: Identifiable

    static func ~= (self: Self, value: Subject) -> Bool
}
