import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension Gender: LoadableFromJSValue, ConvertibleToJSValue {
}
extension Gender {
    var glyphs: String {
        switch (self.sex, self.group.attraction) {
        case (.F, .F): "FF"
        case (.F, .X): "FX"
        case (.F, .M): "FM"
        case (.X, .F): "XF"
        case (.X, .X): "XX"
        case (.X, .M): "XM"
        case (.M, .F): "MF"
        case (.M, .X): "MX"
        case (.M, .M): "MM"
        }
    }
}
