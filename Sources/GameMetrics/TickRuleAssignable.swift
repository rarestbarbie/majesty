import ColorReference
import D
import RealModule

@usableFromInline protocol TickRuleAssignable {
    var range: (min: Double, max: Double) { get }
}
extension TickRuleAssignable {
    @inlinable func tickLogarithmically(
        current: [(y: Double, label: ColorReference?)],
        digits: Int,
        detail: Double = 1 / 5,
    ) -> [TickRule] {
        Self.tickLogarithmically(
            current: current,
            visible: self.range,
            digits: digits,
            detail: detail,
        )
    }
    @inlinable func tickLinearly(
        current: [(y: Double, label: ColorReference?)],
        digits: Int,
        detail: Double = 1 / 5,
    ) -> [TickRule] {
        Self.tickLinearly(
            current: current,
            visible: self.range,
            digits: digits,
            detail: detail,
        )
    }
}
extension TickRuleAssignable {
    @usableFromInline static func tickLogarithmically(
        current: [(y: Double, label: ColorReference?)],
        visible: (min: Double, max: Double),
        digits: Int,
        detail: Double,
    ) -> [TickRule] {
        let linear: (min: Double, max: Double) = (.exp10(visible.min), .exp10(visible.max))
        let range: Double = linear.max - linear.min
        let scale: Double = detail * range

        let decade: Double = .exp10(Double.log10(scale).rounded(.down))
        if  decade <= 0 {
            // this is possible, if scale is 0, which causes `log10` to return `-inf`
            return []
        }

        let step: Double
        switch scale / decade {
        case ...2: step = decade
        case ...5: step = decade * 2
        default: step = decade * 5
        }

        return Self.tick(
            current: current,
            linear: (min: linear.min, max: linear.max, step: step),
            digits: digits,
            transform: Double.log10(_:)
        )
    }

    @usableFromInline static func tickLinearly(
        current: [(y: Double, label: ColorReference?)],
        visible: (min: Double, max: Double),
        digits: Int,
        detail: Double,
    ) -> [TickRule] {
        let range: Double = visible.max - visible.min
        let scale: Double = detail * range

        let decade: Double = .exp10(Double.log10(scale).rounded(.down))
        if  decade <= 0 {
            return []
        }

        let step: Double
        switch scale / decade {
        case ...2: step = decade
        case ...4: step = decade * 2
        default: step = decade * 5
        }

        return Self.tick(
            current: current,
            linear: (min: visible.min, max: visible.max, step: step),
            digits: digits,
        )
    }

    private static func tick(
        current: [(y: Double, label: ColorReference?)],
        linear: (min: Double, max: Double, step: Double),
        digits: Int,
        transform: (Double) -> Double = { $0 }
    ) -> [TickRule] {
        let steps: (first: Int64, last: Int64) = (
            Int64.init((linear.min / linear.step).rounded(.up)),
            Int64.init((linear.max / linear.step).rounded(.down))
        )
        if  steps.last < steps.first {
            return []
        }

        var ticks: [TickRule] = []
        ;   ticks.reserveCapacity(Int.init(steps.last - steps.first) + current.count)

        for i: Int64 in steps.first ... steps.last {
            let y: Double = Double.init(i) * linear.step
            let linear: Decimal? = .init(rounding: y, digits: digits)
            ticks.append(
                TickRule.init(
                    id: 1 + Int.init(i - steps.first),
                    value: transform(y),
                    label: nil,
                    text: linear.map { "\($0[..][.financial])" } ?? "",
                )
            )
        }
        for (y, label): (Double, ColorReference?) in current {
            ticks.append(
                TickRule.init(
                    id: 0,
                    value: transform(y),
                    label: label,
                    text: Decimal.init(rounding: y, digits: digits).map {
                        "\($0[..][.financial])"
                    } ?? "",
                )
            )
        }

        return ticks
    }
}
