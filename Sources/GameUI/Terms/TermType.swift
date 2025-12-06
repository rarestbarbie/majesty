internal import Bijection
import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public enum TermType: Equatable, Hashable {
    case shares
    case stockPrice
    case stockAttraction

    case pop(PopOccupation)
    case buildingsActive
    case buildingsVacant
}
extension TermType: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: String {
        switch self {
        case .shares: "eN"
        case .stockPrice: "eP"
        case .stockAttraction: "eA"
        case .pop(.Livestock): "pA"
        case .pop(.Driver): "pD"
        case .pop(.Editor): "pE"
        case .pop(.Miner): "pM"
        case .pop(.Server): "pS"
        case .pop(.Contractor): "pC"
        case .pop(.Engineer): "pG"
        case .pop(.Farmer): "pF"
        case .pop(.Consultant): "pX"
        case .pop(.Influencer): "pI"
        case .pop(.Aristocrat): "pO"
        case .pop(.Politician): "pP"
        case .buildingsActive: "bA"
        case .buildingsVacant: "bV"
        }
    }
}
extension TermType: ConvertibleToJSValue, LoadableFromJSValue {}
