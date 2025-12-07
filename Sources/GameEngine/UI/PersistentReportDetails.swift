protocol PersistentReportDetails<ID, Focus>: Identifiable, Sendable {
    associatedtype Focus: Sendable
    init(id: Self.ID, focus: Focus)
    mutating func refocus(on focus: Focus)
}
