import Color
import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension Gender: LoadableFromJSValue, ConvertibleToJSValue {
}
extension Gender {
    var sortingRadially: RadialSort {
        switch self {
        case .FT: .FT
        case .FTS: .FTS
        case .FC: .FC
        case .FCS: .FCS
        case .XTL: .XTL
        case .XCL: .XCL
        case .XT: .XT
        case .XC: .XC
        case .XTG: .XTG
        case .XCG: .XCG
        case .MT: .MT
        case .MTS: .MTS
        case .MC: .MC
        case .MCS: .MCS
        }
    }

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
