import Assert
import GameIDs
import JavaScriptInterop
import JavaScriptKit

struct FactoryJob: PopJob, Identifiable {
    let id: FactoryID
    var xp: Int64
    var count: Int64

    var hired: Int64
    var fired: Int64
    var quit: Int64
    var strike: Bool
    var unionization: Double
}
extension FactoryJob {
    init(id: FactoryID) {
        self.init(
            id: id,
            xp: 0,
            count: 0,
            hired: 0,
            fired: 0,
            quit: 0,
            strike: false,
            unionization: 0
        )
    }
}
extension FactoryJob {
    enum ObjectKey: JSString, Sendable {
        case id
        case xp
        case count
        case hired
        case fired
        case quit
        case unionization = "u"
        case strike
    }
}
extension FactoryJob: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.xp] = self.xp == 0 ? nil : self.xp
        js[.count] = self.count == 0 ? nil : self.count
        js[.hired] = self.hired == 0 ? nil : self.hired
        js[.fired] = self.fired == 0 ? nil : self.fired
        js[.quit] = self.quit == 0 ? nil : self.quit
        js[.strike] = self.strike ? true : nil
        js[.unionization] = self.unionization == 0 ? nil : self.unionization
    }
}
extension FactoryJob: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            xp: try js[.xp]?.decode() ?? 0,
            count: try js[.count]?.decode() ?? 0,
            hired: try js[.hired]?.decode() ?? 0,
            fired: try js[.fired]?.decode() ?? 0,
            quit: try js[.quit]?.decode() ?? 0,
            strike: try js[.strike]?.decode() ?? false,
            unionization: try js[.unionization]?.decode() ?? 0,
        )
    }
}

#if TESTABLE
extension FactoryJob: Equatable, Hashable {}
#endif
