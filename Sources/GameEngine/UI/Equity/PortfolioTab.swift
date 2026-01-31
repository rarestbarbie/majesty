import JavaScriptInterop
import GameUI

protocol PortfolioTab: ConvertibleToJSValue, Sendable {
    static var Portfolio: Self { get }
}
