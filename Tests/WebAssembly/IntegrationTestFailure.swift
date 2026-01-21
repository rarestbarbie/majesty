struct IntegrationTestFailure: Error {
    let message: String

    init(message: String) {
        self.message = message
    }
}
extension IntegrationTestFailure: ExpressibleByStringInterpolation {
    init(stringLiteral value: String) {
        self.message = value
    }
}
extension IntegrationTestFailure: CustomStringConvertible {
    var description: String { self.message }
}
