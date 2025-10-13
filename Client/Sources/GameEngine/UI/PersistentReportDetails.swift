protocol PersistentReportDetails<ID, Tab>: Identifiable {
    associatedtype Tab
    init(id: Self.ID, open: Tab)
    var open: Tab { get set }
}
