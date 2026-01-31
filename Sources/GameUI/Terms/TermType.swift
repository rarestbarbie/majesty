internal import Bijection
import GameIDs
import JavaScriptInterop

@frozen public enum TermType: Equatable, Hashable {
    case shares
    case stockPrice
    case stockAttraction
    case portfolio

    case pop(PopOccupation)
    case active
    case vacant
    case profit

    case gdp

    case fee
    case liquidity
}
extension TermType: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: String {
        switch self {
        case .shares: "eN"
        case .stockPrice: "eP"
        case .stockAttraction: "eA"
        case .portfolio: "eV"
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
        case .active: "fA"
        case .vacant: "fV"
        case .profit: "fP"
        case .gdp: "tD"
        case .fee: "mF"
        case .liquidity: "mL"
        }
    }
}
extension TermType: ConvertibleToJSValue, LoadableFromJSValue {}
