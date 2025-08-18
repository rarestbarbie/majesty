import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen @usableFromInline struct PlanetTile {
    let name: String?
    let resources: Set<Resource>

    init(
        name: String? = nil,
        resources: Set<Resource> = []
    ) {
        self.name = name
        self.resources = resources
    }
}
extension PlanetTile {
    @frozen @usableFromInline enum ObjectKey: JSString {
        case name
        case resources
    }
}
extension PlanetTile: JavaScriptEncodable {
    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.name] = self.name
        js[.resources] = self.resources.isEmpty ? nil : self.resources.sorted()
    }
}
extension PlanetTile: JavaScriptDecodable {
    @usableFromInline init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            name: try js[.name]?.decode(),
            resources: .init(try js[.resources]?.decode() ?? [])
        )
    }
}
