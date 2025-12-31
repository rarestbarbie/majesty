import Bijection
import GameIDs

extension Gender {
    @Bijection(label: "singularTabular") @inlinable public var singularTabular: String {
        switch self {
        case .FT: "Transgender Woman"
        case .FTS: "Transgender Woman (Heterosexual)"
        case .FC: "Cisgender Woman"
        case .FCS: "Cisgender Woman (Heterosexual)"
        case .XTL: "Transgender Nonbinary (Sapphic)"
        case .XT: "Transgender Nonbinary"
        case .XTG: "Transgender Nonbinary (Achillean)"
        case .XCL: "Intersex Nonbinary (Sapphic)"
        case .XC: "Intersex Nonbinary"
        case .XCG: "Intersex Nonbinary (Achillean)"
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
        case .XTL: "Transgender Nonbinary (Sapphic)"
        case .XT: "Transgender Nonbinary (Isosexual)"
        case .XTG: "Transgender Nonbinary (Achillean)"
        case .XCL: "Intersex Nonbinary (Sapphic)"
        case .XC: "Intersex Nonbinary (Isosexual)"
        case .XCG: "Intersex Nonbinary (Achillean)"
        case .MT: "Transgender Men"
        case .MTS: "Transgender Men (Heterosexual)"
        case .MC: "Cisgender Men"
        case .MCS: "Cisgender Men (Heterosexual)"
        }
    }

    @inlinable public var pluralLong: String {
        switch self {
        case .FT: "Transgender Women"
        case .FTS: "Transgender Straight Women"
        case .FC: "Cisgender Women"
        case .FCS: "Cisgender Straight Women"
        case .XTL: "Nonbinary Transgender Sapphics"
        case .XT: "Nonbinary Transgender Isosexuals"
        case .XTG: "Nonbinary Transgender Achilleans"
        case .XCL: "Nonbinary Intersex Sapphics"
        case .XC: "Nonbinary Intersex Isosexuals"
        case .XCG: "Nonbinary Intersex Achilleans"
        case .MT: "Transgender Men"
        case .MTS: "Transgender Straight Men"
        case .MC: "Cisgender Men"
        case .MCS: "Cisgender Straight Men"
        }
    }

    @inlinable public var pluralShort: String {
        switch self {
        case .FT: "Binary trans lesbians"
        case .FTS: "Straight trans women"
        case .FC: "Binary cis lesbians"
        case .FCS: "Straight cis women"
        case .XTL: "Nonbinary trans lesbians"
        case .XT: "Nonbinary isosexual trans people"
        case .XTG: "Nonbinary achillean trans people"
        case .XCL: "Nonbinary intersex lesbians"
        case .XC: "Nonbinary isosexual intersex people"
        case .XCG: "Nonbinary achillean intersex people"
        case .MT: "Binary gay trans men"
        case .MTS: "Straight trans men"
        case .MC: "Binary gay cis men"
        case .MCS: "Straight cis men"
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
