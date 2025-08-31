import Vector

extension PopContext {
    struct Tiers {
        private var vector: Vector3
    }
}
extension PopContext.Tiers {
    init(l: Double, e: Double, x: Double) {
        self.init(vector: .init(l, e, x))
    }
    init() {
        self.init(vector: .init(0, 0, 0))
    }
}
extension PopContext.Tiers {
    var l: Double {
        get {
            self.vector.x
        }
        set(value) {
            self.vector.x = value
        }
    }

    var e: Double {
        get {
            self.vector.y
        }
        set(value) {
            self.vector.y = value
        }
    }

    var x: Double {
        get {
            self.vector.z
        }
        set(value) {
            self.vector.z = value
        }
    }
}
extension PopContext.Tiers {
    static func + (a: Self, b: Self) -> Self {
        .init(vector: a.vector + b.vector)
    }
    static func * (a: Self, b: Self) -> Self {
        .init(vector: a.vector * b.vector)
    }
    static func * (self: Self, scale: Double) -> Self {
        .init(vector: self.vector * scale)
    }
    static func * (scale: Double, self: Self) -> Self {
        .init(vector: scale * self.vector)
    }
}
