import GameEngine
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

@frozen @usableFromInline struct PlanetGridCell {
    let id: HexCoordinate
    let shape: (HexagonPath, HexagonPath?)
    let color: Color
}
extension PlanetGridCell {
    @frozen @usableFromInline enum ObjectKey: JSString, Sendable {
        case id
        case d0
        case d1
        case color
    }
}
extension PlanetGridCell: JavaScriptEncodable {
    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.d0] = self.shape.0.d
        js[.d1] = self.shape.1?.d
        js[.color] = self.color
    }
}
