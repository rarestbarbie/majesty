protocol PersistentReportDetails<ID, Focus>: Identifiable {
    associatedtype Focus
    init(id: Self.ID, focus: Focus)
    mutating func refocus(on focus: Focus)
}
