import JavaScriptInterop
import JavaScriptKit

extension GameUI {
    @frozen public enum ScreenType: JSString,
        LoadableFromJSValue,
        ConvertibleToJSValue,
        Sendable {
        case Planet
        case Infrastructure
        case Production
        case Population
        case Trade
    }
}
