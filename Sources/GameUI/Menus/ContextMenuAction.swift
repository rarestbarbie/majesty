import JavaScriptInterop

@frozen public enum ContextMenuAction: String, LoadableFromJSValue, ConvertibleToJSValue {
    case SwitchToPlayer
}
