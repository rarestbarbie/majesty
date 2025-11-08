protocol PersistentReport<Request> {
    associatedtype Request

    init()

    mutating func select(request: Request) throws
    mutating func update(from snapshot: borrowing GameSnapshot) throws
}
extension PersistentReport {
    mutating func open(request: Request, snapshot: borrowing GameSnapshot) throws -> Self {
        try self.select(request: request)
        try self.update(from: snapshot)
        return self
    }
}
