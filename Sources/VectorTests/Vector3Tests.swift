import Testing
import Vector

@Suite struct Vector3Tests {
    @Test func dotProductWithPerpendiculars() {
        let v1: Vector3 = .init(1, 0, 0)
        let v2: Vector3 = .init(0, 1, 0)

        #expect(v1 <> v2 == 0)

        let v3: Vector3 = .init(0, 1, 0)
        let v4: Vector3 = .init(0, 0, 1)

        #expect(v3 <> v4 == 0)
    }

    @Test func dotProductWithParallel() {
        let v1: Vector3 = .init(2, 0, 0)
        let v2: Vector3 = .init(3, 0, 0)

        #expect(v1 <> v2 == 6)

        let v3: Vector3 = .init(2, 4, 6)
        let v4: Vector3 = .init(2, 4, 6)

        #expect(v3 <> v4 == 56)
    }

    @Test func dotProductWithMixedVectors() {
        let v1: Vector3 = .init(1, 2, 3)
        let v2: Vector3 = .init(4, -5, 6)

        #expect(v1 <> v2 == 12)

        let v3: Vector3 = .init(-1.5, 2.5, -3.5)
        let v4: Vector3 = .init(2.0, 4.0, 6.0)

        #expect(v3 <> v4 == -14)
    }

    @Test func crossProductWithPerpendiculars() {
        let v1: Vector3 = .init(1, 0, 0)
        let v2: Vector3 = .init(0, 1, 0)
        let result: Vector3 = v1 >< v2

        #expect(result.x == 0)
        #expect(result.y == 0)
        #expect(result.z == 1)

        // Verify perpendicular to both inputs
        #expect((result <> v1) == 0)
        #expect((result <> v2) == 0)
    }

    @Test func crossProductWithParallel() {
        let v1: Vector3 = .init(2, 4, 6)
        let v2: Vector3 = .init(1, 2, 3)
        let result: Vector3 = v1 >< v2

        // Cross product of parallel vectors should be zero
        #expect(result.x == 0)
        #expect(result.y == 0)
        #expect(result.z == 0)
    }

    @Test func crossProductProperties() {
        let v1: Vector3 = .init(3, -2, 1)
        let v2: Vector3 = .init(1, 4, -2)
        let result: Vector3 = v1 >< v2

        // Verify correct result
        #expect(result.x == 0)
        #expect(result.y == 7)
        #expect(result.z == 14)

        // Verify perpendicular to both inputs
        #expect((result <> v1) == 0)
        #expect((result <> v2) == 0)

        // Anti-commutativity: a × b = -(b × a)
        let reversed: Vector3 = v2 >< v1
        #expect(reversed.x == -result.x)
        #expect(reversed.y == -result.y)
        #expect(reversed.z == -result.z)
    }
}
