protocol PersistentReport<Subject> {
    associatedtype Subject
    associatedtype Details
    associatedtype Filter

    init()

    mutating func select(subject: Subject, details: Details?, filter: Filter?) throws
    mutating func update(on map: borrowing GameMap, in context: GameContext) throws
}
extension PersistentReport {
    mutating func open(
        subject: Subject,
        details: Details?,
        filter: Filter?,
        on map: borrowing GameMap,
        in context: GameContext
    ) throws -> Self {
        try self.select(subject: subject, details: details, filter: filter)
        try self.update(on: map, in: context)
        return self
    }
}
