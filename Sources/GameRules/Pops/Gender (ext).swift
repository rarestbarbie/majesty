import Bijection
import GameIDs

extension Gender {
    @Bijection(label: "singularTabular") @inlinable public var singularTabular: String {
        switch self {
        case .FT: "Transgender Woman"
        case .FTS: "Transgender Woman (Heterosexual)"
        case .FC: "Cisgender Woman"
        case .FCS: "Cisgender Woman (Heterosexual)"
        case .XTL: "Transgender Nonbinary (Lesbian)"
        case .XT: "Transgender Nonbinary"
        case .XTG: "Transgender Nonbinary (Gay)"
        case .XCL: "Intersex Nonbinary (Lesbian)"
        case .XC: "Intersex Nonbinary"
        case .XCG: "Intersex Nonbinary (Gay)"
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
        case .XTL: "Transgender Nonbinary (Lesbian)"
        case .XT: "Transgender Nonbinary"
        case .XTG: "Transgender Nonbinary (Gay)"
        case .XCL: "Intersex Nonbinary (Lesbian)"
        case .XC: "Intersex Nonbinary"
        case .XCG: "Intersex Nonbinary (Gay)"
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
        case .XTL: "Nonbinary Transgender Lesbians"
        case .XT: "Nonbinary Transgender Pansexuals"
        case .XTG: "Nonbinary Transgender Gays"
        case .XCL: "Nonbinary Intersex Lesbians"
        case .XC: "Nonbinary Intersex Pansexuals"
        case .XCG: "Nonbinary Intersex Gays"
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
