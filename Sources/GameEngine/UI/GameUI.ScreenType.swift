import JavaScriptInterop
import JavaScriptKit

extension GameUI {
    @frozen public enum ScreenType: JSString, LoadableFromJSValue, ConvertibleToJSValue {
        case Planet
        case Production
        case Population
        case Trade
    }
}
