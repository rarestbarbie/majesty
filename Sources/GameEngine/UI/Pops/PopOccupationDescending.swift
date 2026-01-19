import GameIDs
import JavaScriptInterop

@frozen @usableFromInline struct PopOccupationDescending: RawRepresentable {
    @usableFromInline let rawValue: PopOccupation
    @inlinable init(rawValue: PopOccupation) {
        self.rawValue = rawValue
    }
}
extension PopOccupationDescending: CustomStringConvertible, LosslessStringConvertible {
    @inlinable var description: String { self.rawValue.description }
    @inlinable init?(_ description: some StringProtocol) {
        guard let rawValue: PopOccupation = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
extension PopOccupationDescending: ConvertibleToJSValue, LoadableFromJSValue {}
extension PopOccupationDescending: Comparable {
    @inlinable static func < (a: Self, b: Self) -> Bool { a.rawValue > b.rawValue }
}
