import Assert
import GameState
import JavaScriptInterop
import JavaScriptKit
import Random

@frozen public struct FactoryJob {
    public let at: FactoryID
    public private(set) var xp: Int64
    public private(set) var count: Int64

    public private(set) var hired: Int64
    public private(set) var fired: Int64
    public private(set) var quit: Int64
    public private(set) var strike: Bool
    public private(set) var unionization: Double
}
extension FactoryJob {
    init(at: FactoryID) {
        self.init(at: at, xp: 0, count: 0, hired: 0, fired: 0, quit: 0, strike: false, unionization: 0)
    }

    mutating func fireAll() {
        self.fired += self.count
        self.count = 0
    }

    mutating func fire(_ layoff: inout FactoryJobLayoffBlock?) {
        guard
        let size: Int64 = layoff?.size, size > 0 else {
            return
        }

        if  size > self.count {
            layoff?.size -= self.count
            self.fireAll()
        } else {
            layoff = nil
            self.fire(size)
        }
    }

    mutating func fire(_ count: Int64) {
        self.fired += count
        self.count -= count
    }

    mutating func hire(_ count: Int64) {
        self.hired += count
        self.count += count
    }

    mutating func quit(_ count: Int64) {
        self.quit += count
        self.count -= count

        #assert(self.count >= 0, "Negative employee count (count = \(self.count)) in job \(self.at)!!!")
    }

    mutating func quit(
        rate: Double,
        using generator: inout some RandomNumberGenerator
    ) {
        let quit: Int64 = Binomial[self.count, rate].sample(using: &generator)

        self.quit += quit
        self.count -= quit
    }

    mutating func turn() {
        self.hired = 0
        self.fired = 0
        self.quit = 0
    }
}
extension FactoryJob: Identifiable {
    @inlinable public var id: FactoryID { self.at }
}
extension FactoryJob {
    @frozen public enum ObjectKey: JSString, Sendable {
        case at
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
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.at] = self.at
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
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            at: try js[.at].decode(),
            xp: try js[.xp]?.decode() ?? 0,
            count: try js[.count].decode(),
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
