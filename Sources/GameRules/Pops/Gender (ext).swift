import Bijection
import GameIDs

extension Gender {
    @Bijection(label: "singularTabular") @inlinable public var singularTabular: String {
        switch self {
        case .FT: "Transgender Woman"
        case .FTS: "Transgender Woman (Heterosexual)"
        case .FC: "Cisgender Woman"
        case .FCS: "Cisgender Woman (Heterosexual)"
        case .XTL: "Non-Binary (Lesbian)"
        case .XT: "Non-Binary"
        case .XTG: "Non-Binary (Gay)"
        case .XCL: "Intersex (Lesbian)"
        case .XC: "Intersex"
        case .XCG: "Intersex (Gay)"
        case .MT: "Transgender Man"
        case .MTS: "Transgender Man (Heterosexual)"
        case .MC: "Cisgender Man"
        case .MCS: "Cisgender Man (Heterosexual)"
        }
    }

    @Bijection(label: "pluralTabular") @inlinable public var pluralTabular: String {
        switch self {
        case .FT: "Transgender Women"
        case .FTS: "Transgender Women (Heterosexual)"
        case .FC: "Cisgender Women"
        case .FCS: "Cisgender Women (Heterosexual)"
        case .XTL: "Non-Binary (Lesbian)"
        case .XT: "Non-Binary"
        case .XTG: "Non-Binary (Gay)"
        case .XCL: "Intersex (Lesbian)"
        case .XC: "Intersex"
        case .XCG: "Intersex (Gay)"
        case .MT: "Transgender Men"
        case .MTS: "Transgender Men (Heterosexual)"
        case .MC: "Cisgender Men"
        case .MCS: "Cisgender Men (Heterosexual)"
        }
    }

    @inlinable public var plural: String {
        switch self {
        case .FT: "Transgender Women"
        case .FTS: "Transgender Straight Women"
        case .FC: "Cisgender Women"
        case .FCS: "Cisgender Straight Women"
        case .XTL: "Non-Binary Lesbians"
        case .XT: "Non-Binary"
        case .XTG: "Non-Binary Gays"
        case .XCL: "Intersex Lesbians"
        case .XC: "Intersex"
        case .XCG: "Intersex Gays"
        case .MT: "Transgender Men"
        case .MTS: "Transgender Straight Men"
        case .MC: "Cisgender Men"
        case .MCS: "Cisgender Straight Men"
        }
    }

    @Bijection(label: "code") @inlinable public var code: Symbol {
        switch self {
        case .FT: "FT"
        case .FTS: "FTS"
        case .FC: "FC"
        case .FCS: "FCS"

        case .XTL: "XTL"
        case .XT: "XT"
        case .XTG: "XTG"
        case .XCL: "XCL"
        case .XC: "XC"
        case .XCG: "XCG"

        case .MT: "MT"
        case .MTS: "MTS"
        case .MC: "MC"
        case .MCS: "MCS"
        }
    }
}
