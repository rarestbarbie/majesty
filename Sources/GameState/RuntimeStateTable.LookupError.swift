extension RuntimeStateTable {
    @frozen public enum LookupError: Error {
        case undefined(_ id: ElementContext.State.ID)
    }
}

extension RuntimeStateTable.LookupError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .undefined(let id):
            "no such object of type '\(ElementContext.self)' with id '\(id)'"
        }
    }
}
