import GameIDs
import JavaScriptInterop

extension PopAttributesDescription {
    struct Predicate {
        let clauses: [Clause]
    }
}
extension PopAttributesDescription.Predicate: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case occupations
        case occupation

        case strata
        case stratum

        case biologies
        case biology

        case sexes
        case sex

        case heterosexual
        case transgender
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        var clauses: [Clause] = []

        if  let symbol: Symbol = try js[.occupation]?.decode() {
            clauses.append(.occupation(in: [symbol]))

            // raise errors if these are found, as they conflict
            try js[.occupations]?.decode(to: Never.self)
            try js[.stratum]?.decode(to: Never.self)
            try js[.strata]?.decode(to: Never.self)
        } else if
            let symbols: [Symbol] = try js[.occupations]?.decode() {
            clauses.append(.occupation(in: symbols))

            try js[.stratum]?.decode(to: Never.self)
            try js[.strata]?.decode(to: Never.self)
        } else if
            let symbol: Symbol = try js[.stratum]?.decode() {
            clauses.append(.stratum(in: [symbol]))
            try js[.strata]?.decode(to: Never.self)
        } else if
            let symbols: [Symbol] = try js[.strata]?.decode() {
            clauses.append(.stratum(in: symbols))
        }

        if  let symbol: Symbol = try js[.biology]?.decode() {
            clauses.append(.biology(in: [symbol]))
            try js[.biologies]?.decode(to: Never.self)
        } else if
            let symbols: [Symbol] = try js[.biologies]?.decode() {
            clauses.append(.biology(in: symbols))
        }

        if  let value: Sex = try js[.sex]?.decode() {
            clauses.append(.sex(in: [value]))
            try js[.sexes]?.decode(to: Never.self)
        } else if
            let values: [Sex] = try js[.sexes]?.decode() {
            clauses.append(.sex(in: values))
        }

        if  let value: Bool = try js[.heterosexual]?.decode() {
            clauses.append(.heterosexual(value))
        }

        if  let value: Bool = try js[.transgender]?.decode() {
            clauses.append(.transgender(value))
        }

        self.init(clauses: clauses)
    }
}
