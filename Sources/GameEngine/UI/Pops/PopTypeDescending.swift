import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen @usableFromInline struct PopTypeDescending: RawRepresentable {
    @usableFromInline let rawValue: PopType
    @inlinable init(rawValue: PopType) {
        self.rawValue = rawValue
    }
}
extension PopTypeDescending: CustomStringConvertible, LosslessStringConvertible {
    @inlinable var description: String { self.rawValue.description }
    @inlinable init?(_ description: some StringProtocol) {
        guard let rawValue: PopType = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
extension PopTypeDescending: ConvertibleToJSValue, LoadableFromJSValue {}
extension PopTypeDescending: Comparable {
    @inlinable static func < (a: Self, b: Self) -> Bool { a.rawValue > b.rawValue }
}
