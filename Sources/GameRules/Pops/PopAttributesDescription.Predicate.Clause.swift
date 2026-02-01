import GameIDs

extension PopAttributesDescription.Predicate {
    enum Clause {
        case occupation(in: [Symbol])
        case stratum(in: [Symbol])
        case biology(in: [Symbol])
        case sex(in: [Sex])

        case heterosexual(Bool)
        case transgender(Bool)
    }
}
