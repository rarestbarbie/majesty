protocol PersistentReport<Request>: Sendable {
    associatedtype Request

    init()

    mutating func select(request: Request) throws
}
