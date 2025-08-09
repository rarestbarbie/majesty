import JavaScriptKit

extension TooltipInstruction {
    @frozen public enum Sign: JSString, ConvertibleToJSValue {
        case pos
        case neg
    }
}
