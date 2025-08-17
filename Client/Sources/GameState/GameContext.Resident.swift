extension GameContext {
    enum Resident {
        case factory(Int)
        case pop(Int)
    }
}
extension GameContext.Resident {
    var factory: Int? {
        switch self {
        case .factory(let i): i
        case .pop: nil
        }
    }

    var pop: Int? {
        switch self {
        case .factory: nil
        case .pop(let i): i
        }
    }
}
