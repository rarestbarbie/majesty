protocol PersistentReport<Subject> {
    associatedtype Subject
    associatedtype Details
    associatedtype Filter

    init()

    mutating func select(subject: Subject, details: Details?, filter: Filter?) throws
    mutating func update(from snapshot: borrowing GameSnapshot) throws
}
extension PersistentReport {
    mutating func open(
        subject: Subject,
        details: Details?,
        filter: Filter?,
        snapshot: borrowing GameSnapshot
    ) throws -> Self {
        try self.select(subject: subject, details: details, filter: filter)
        try self.update(from: snapshot)
        return self
    }
}
