import JavaScriptInterop

enum PlayerEventID: String, LoadableFromJSValue, ConvertibleToJSValue {
    case Faster
    case Slower
    case Pause
    case Tick
}
