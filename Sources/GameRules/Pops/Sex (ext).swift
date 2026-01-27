import GameIDs

extension Sex {
    @inlinable public var pluralUppercased: String {
        switch self {
        case .F: "Women"
        case .X: "Nonbinary people"
        case .M: "Men"
        }
    }

    @inlinable public var pluralLowercased: String {
        switch self {
        case .F: "women"
        case .X: "nonbinary people"
        case .M: "men"
        }
    }
}
