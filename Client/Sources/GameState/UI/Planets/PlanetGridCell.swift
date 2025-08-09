import GameEngine
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

@frozen @usableFromInline struct PlanetGridCell {
    let id: HexCoordinate
    let shape: HexagonPath
    let color: Color
}
extension PlanetGridCell {
    @frozen @usableFromInline enum ObjectKey: JSString, Sendable {
        case id
        case shape = "d"
        case color
    }
}
extension PlanetGridCell: JavaScriptEncodable {
    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.shape] = self.shape.d
        js[.color] = self.color
    }
}
