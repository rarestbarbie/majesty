import JavaScriptKit
import JavaScriptInterop

extension GameAPI {
    struct Arguments {
        private let list: [JSValue]
        private var index: Int

        init(list: [JSValue]) {
            self.list = list
            self.index = list.startIndex
        }
    }
}
extension GameAPI.Arguments {
    mutating func next<T>(
        as _: T.Type = T.self
    ) throws -> T where T: LoadableFromJSValue {
        guard self.index < list.endIndex else {
            throw GameAPI.ArgumentConventionError.missing(index: index)
        }
        defer { index += 1 }
        do {
            return try .load(from: list[index])
        } catch let error {
            throw GameAPI.ArgumentConventionError.invalid(index: index, problem: error)
        }
    }
}
