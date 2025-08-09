extension GameAPI {
    enum ArgumentConventionError: Error {
        case missing(index: Int)
        case invalid(index: Int, problem: any Error)
    }
}
extension GameAPI.ArgumentConventionError: CustomStringConvertible {
    var description: String {
        switch self {
        case .missing(let index):
            "Missing argument at index \(index)"
        case .invalid(let index, let problem):
            "Invalid argument at index \(index): \(problem)"
        }
    }
}
