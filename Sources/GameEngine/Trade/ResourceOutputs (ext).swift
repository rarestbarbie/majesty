import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension ResourceOutputs {
    @inline(__always) func snapshot<ID>(
        into table: inout [ID: InventorySnapshot.Produced.Value],
        as id: (Resource) -> ID
    ) {
        for (resource, output): (Resource, ResourceOutput) in self.segmented {
            table[id(resource)] = .init(output: output, tradeable: false)
        }
        for (resource, output): (Resource, ResourceOutput) in self.tradeable {
            table[id(resource)] = .init(output: output, tradeable: true)
        }
    }
}
extension ResourceOutputs {
    var valueSold: Int64 {
        self.segmented.values.reduce(0) { $0 + $1.valueSold } +
        self.tradeable.values.reduce(0) { $0 + $1.valueSold }
    }
}
extension ResourceOutputs {
    @frozen public enum ObjectKey: JSString, Sendable {
        case segmented = "s"
        case tradeable = "t"
    }
}
extension ResourceOutputs: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.segmented] = self.segmented
        js[.tradeable] = self.tradeable
    }
}
extension ResourceOutputs: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            segmented: try js[.segmented].decode(),
            tradeable: try js[.tradeable].decode(),
        )
    }
}
