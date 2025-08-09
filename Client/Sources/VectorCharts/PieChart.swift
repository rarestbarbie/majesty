import Vector

@frozen public enum PieChart<Key, Value> where Key: Hashable {
    case circle(Circle)
    case slices([Slice])
}
extension PieChart: RandomAccessCollection {
    @inlinable public var startIndex: Int {
        switch self {
        case .circle:               0
        case .slices(let slices):   slices.startIndex
        }
    }

    @inlinable public var endIndex: Int {
        switch self {
        case .circle:               1
        case .slices(let slices):   slices.endIndex
        }
    }

    @inlinable public subscript(index: Int) -> Sector {
        switch self {
        case .circle(let circle):
            return .init(id: circle.id, value: circle.value, slice: nil)
        case .slices(let slices):
            let slice: Slice = slices[index]
            return .init(
                id: slice.id,
                value: slice.value,
                slice: (share: slice.share, d: slice.path)
            )
        }
    }
}
extension PieChart {
    @inlinable public init(
        values: some Sequence<(Key, (share: Int64, Value))>,
    ) {
        let sectors: [(Key, (share: Int64, Value))] = values.filter { $1.share > 0 }

        guard sectors.startIndex < sectors.endIndex
        else {
            self = .slices([])
            return
        }

        let divisor: Double = .init(sectors.reduce(into: 0) { $0 += $1.1.share })
        let last: Int = sectors.index(before: sectors.endIndex)

        var start: Vector2 = .init(1, 0)
        var w: Int64 = 0

        var slices: [Slice] = []
            slices.reserveCapacity(sectors.count)

        for (id, (share, value)): (Key, (Int64, Value)) in sectors[..<last] {
            w += share

            let f: Double = Double.init(w) / divisor
            let r: Double = 2 * Double.pi * f

            let share: Double = Double.init(share) / divisor
            let slice: Slice = .init(
                id: id,
                value: value,
                geometry: .init(share: share, from: start, to: r)
            )

            start = slice.geometry.endArc
            slices.append(slice)
        }

        let (id, (share, value)): (Key, (Int64, Value)) = sectors[last]

        if w > 0 {
            let share: Double = Double.init(share) / divisor
            let slice: Slice = .init(
                id: id,
                value: value,
                geometry: .init(
                    share: share,
                    startArc: start,
                    endArc: .init(1, 0),
                    end: 2 * Double.pi
                )
            )

            slices.append(slice)
            self = .slices(slices)
        }
        else {
            self = .circle(.init(id: id, value: value))
        }
    }
}
