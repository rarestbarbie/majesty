import ColorText
import D
import RealModule

@usableFromInline protocol TickRuleAssignable {
    var min: Double { get }
    var max: Double { get }
}
extension TickRuleAssignable {
    @inlinable func tickLogarithmically(
        current: (y: Double, style: ColorText.Style?),
        detail: Double = 1 / 5
    ) -> [TickRule] {
        Self.tickLogarithmically(
            current: current,
            visible: (min: self.min, max: self.max),
            detail: detail
        )
    }
    @inlinable func tickLinearly(
        current: (y: Double, style: ColorText.Style?),
        detail: Double = 1 / 5
    ) -> [TickRule] {
        Self.tickLinearly(
            current: current,
            visible: (min: self.min, max: self.max),
            detail: detail
        )
    }
}
extension TickRuleAssignable {
    @usableFromInline static func tickLogarithmically(
        current: (y: Double, style: ColorText.Style?),
        visible: (min: Double, max: Double),
        detail: Double
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
        case ...3: step = decade
        case ...6: step = decade * 2
        default: step = decade * 5
        }

        return Self.tick(
            current: current,
            linear: (min: linear.min, max: linear.max, step: step),
            transform: Double.log10(_:)
        )
    }

    @usableFromInline static func tickLinearly(
        current: (y: Double, style: ColorText.Style?),
        visible: (min: Double, max: Double),
        detail: Double
    ) -> [TickRule] {
        let range: Double = visible.max - visible.min
        let scale: Double = detail * range

        let decade: Double = .exp10(Double.log10(scale).rounded(.down))
        if  decade <= 0 {
            return []
        }

        let step: Double
        switch scale / decade {
        case ...1: step = decade
        case ...3: step = decade * 2
        default: step = decade * 5
        }

        return Self.tick(
            current: current,
            linear: (min: visible.min, max: visible.max, step: step)
        )
    }

    private static func tick(
        current: (y: Double, style: ColorText.Style?),
        linear: (min: Double, max: Double, step: Double),
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
        ;   ticks.reserveCapacity(Int.init(steps.last - steps.first) + 1)

        for i: Int64 in steps.first ... steps.last {
            let y: Double = Double.init(i) * linear.step
            let linear: Decimal? = .init(rounding: y, places: 2)
            ticks.append(
                TickRule.init(
                    id: 1 + Int.init(i - steps.first),
                    value: transform(y),
                    label: linear.map { "\($0[..])" } ?? "",
                    style: nil
                )
            )
        }

        ticks.append(
            TickRule.init(
                id: 0,
                value: transform(current.y),
                label: Decimal.init(rounding: current.y, places: 2).map { "\($0[..])" } ?? "",
                style: current.style
            )
        )

        return ticks
    }
}
