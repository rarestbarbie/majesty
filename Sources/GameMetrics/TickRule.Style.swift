import JavaScriptKit

extension TickRule {
    @frozen public enum Style {
        case pos
        case neg
    }
}
extension TickRule.Style {
    var id: JSString {
        switch self {
        case .pos: "pos"
        case .neg: "neg"
        }
    }
}
