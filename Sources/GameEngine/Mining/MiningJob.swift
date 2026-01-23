import GameIDs
import GameEconomy
import JavaScriptInterop

struct MiningJob: PopJob, Identifiable {
    let id: MineID
    var count: Int64
    var hired: Int64
    var fired: Int64
    var quit: Int64
    var out: ResourceOutputs
}
extension MiningJob {
    init(id: MineID) {
        self.init(
            id: id,
            count: 0,
            hired: 0,
            fired: 0,
            quit: 0,
            out: .empty
        )
    }
}
extension MiningJob {
    enum ObjectKey: JSString, Sendable {
        case id
        case count
        case hired
        case fired
        case quit
        case out
    }
}
extension MiningJob: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.count] = self.count == 0 ? nil : self.count
        js[.hired] = self.hired == 0 ? nil : self.hired
        js[.fired] = self.fired == 0 ? nil : self.fired
        js[.quit] = self.quit == 0 ? nil : self.quit
        js[.out] = self.out
    }
}
extension MiningJob: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            count: try js[.count].decode(),
            hired: try js[.hired]?.decode() ?? 0,
            fired: try js[.fired]?.decode() ?? 0,
            quit: try js[.quit]?.decode() ?? 0,
            out: try js[.out].decode()
        )
    }
}

#if TESTABLE
extension MiningJob: Equatable {}
#endif
