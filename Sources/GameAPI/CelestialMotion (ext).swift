import GameEngine
import JavaScriptKit
import Vector

extension CelestialMotion {
    func rendered() -> JSTypedArray<Float> {
        // This is probably faster than repeatedly calling a foreign subscript
        var array: [Float] = [] ; array.reserveCapacity(361 * 3)
        for i: Int in 0 ... 360 {
            let phi: Double = Double.init(i) * (.pi / 180.0)
            let p: Vector3 = self.position(phi)

            array.append(Float.init(p.x))
            array.append(Float.init(p.y))
            array.append(Float.init(p.z))
        }
        return JSTypedArray<Float>.init(array)
    }
}
