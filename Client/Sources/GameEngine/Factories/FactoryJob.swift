import Assert
import GameState
import JavaScriptInterop
import JavaScriptKit
import Random

@frozen public struct FactoryJob {
    public let at: GameID<Factory>
    public private(set) var hire: Int64
    public private(set) var fire: Int64
    public private(set) var quit: Int64
    public private(set) var u: Int64
    public private(set) var n: Int64
    public private(set) var ux: Int
    public private(set) var nx: Int
    public private(set) var strike: Bool
}
extension FactoryJob {
    init(at: GameID<Factory>) {
        self.init(at: at, hire: 0, fire: 0, quit: 0, u: 0, n: 0, ux: 0, nx: 0, strike: false)
    }

    mutating func fireAll() {
        self.fire += self.n
        self.fire += self.u
        self.n = 0
        self.u = 0
    }

    // mutating func fire(_ count: Int64) {
    //     self.fire += count
    //     self.n -= count
    // }

    mutating func hire(_ count: Int64) {
        self.hire += count
        self.n += count
    }

    mutating func quit(_ count: Int64) {
        self.quit += count
        self.n -= count

        if self.n < 0 {
            self.u += self.n
            self.n = 0
        }

        #assert(self.u >= 0, "Negative employee count (u = \(self.u)) in job \(self.at)!!!")
        #assert(self.n >= 0, "Negative employee count (n = \(self.n)) in job \(self.at)!!!")
    }

    mutating func quit(
        nonunionRate: Double,
        unionRate: Double,
        using generator: inout some RandomNumberGenerator
    ) {
        let qn: Int64 = Binomial[self.n, nonunionRate].sample(using: &generator)
        let qu: Int64 = Binomial[self.u, unionRate].sample(using: &generator)

        self.quit += qn
        self.quit += qu
        self.n -= qn
        self.u -= qu
    }

    mutating func turn() {
        self.hire = 0
        self.fire = 0
        self.quit = 0
    }
}
extension FactoryJob: Identifiable {
    @inlinable public var id: GameID<Factory> { self.at }
}
extension FactoryJob {
    var employed: Int64 {
        self.u + self.n
    }
}
extension FactoryJob {
    @frozen public enum ObjectKey: JSString, Sendable {
        case at
        case hire
        case fire
        case quit
        case u
        case n
        case ux
        case nx
        case strike
    }
}
extension FactoryJob: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.at] = self.at
        js[.hire] = self.hire == 0 ? nil : self.hire
        js[.fire] = self.fire == 0 ? nil : self.fire
        js[.quit] = self.quit == 0 ? nil : self.quit
        js[.u] = self.u
        js[.n] = self.n
        js[.ux] = self.ux
        js[.nx] = self.nx
        js[.strike] = self.strike ? true : nil
    }
}
extension FactoryJob: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            at: try js[.at].decode(),
            hire: try js[.hire]?.decode() ?? 0,
            fire: try js[.fire]?.decode() ?? 0,
            quit: try js[.quit]?.decode() ?? 0,
            u: try js[.u].decode(),
            n: try js[.n].decode(),
            ux: try js[.ux].decode(),
            nx: try js[.nx].decode(),
            strike: try js[.strike]?.decode() ?? false,
        )
    }
}

#if TESTABLE
extension FactoryJob: Equatable, Hashable {}
#endif
