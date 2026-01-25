@dynamicMemberLookup struct Mean<Dimensions> {
    private var fields: Dimensions
    private var weight: Double

    init(fields: Dimensions, weight: Double) {
        self.fields = fields
        self.weight = weight
    }
}
extension Mean {
    var population: Double { self.weight }
}
extension Mean: Equatable where Dimensions: Equatable {}
extension Mean: AdditiveArithmetic where Dimensions: AdditiveArithmetic {
    static var zero: Self { .init(fields: .zero, weight: 0) }

    static func + (self: consuming Self, other: Self) -> Self {
        self += other
        return self
    }
    static func - (self: consuming Self, other: Self) -> Self {
        self -= other
        return self
    }
}
extension Mean where Dimensions: AdditiveArithmetic {
    static func += (self: inout Self, other: Self) {
        self.fields += other.fields
        self.weight += other.weight
    }
    static func -= (self: inout Self, other: Self) {
        self.fields -= other.fields
        self.weight -= other.weight
    }
}
extension Mean where Dimensions: BinaryFloatingPoint {
    var defined: Double? {
        self.weight > 0 ? (Double.init(self.fields) / self.weight) : nil
    }
}
extension Mean where Dimensions: BinaryInteger {
    var defined: Double? {
        self.weight > 0 ? (Double.init(self.fields) / self.weight) : nil
    }
}
extension Mean {
    subscript<T>(
        dynamicMember keyPath: KeyPath<Dimensions, T>
    ) -> Double where T: BinaryFloatingPoint {
        self[dynamicMember: keyPath].defined ?? 0
    }
    subscript<T>(
        dynamicMember keyPath: KeyPath<Dimensions, T>
    ) -> Double where T: BinaryInteger {
        self[dynamicMember: keyPath].defined ?? 0
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> Mean<T> {
        .init(fields: self.fields[keyPath: keyPath], weight: self.weight)
    }
}
