import ColorText
import D
import GameConditions
import GameEconomy
import GameRules

extension [ResourceNeed] {
    mutating func update(
        inputs: [ResourceInput],
        tier: ResourceNeedTier,
        rules: GameRules,
    ) {
        for input: ResourceInput in inputs {
            self.append(ResourceNeed.init(label: rules[input.id], input: input, tier: tier))
        }
    }
}
extension [ConditionListItem] {
    static func list(_ headings: ColorText..., breakdown: ConditionBreakdown) -> Self {
        var list: Self = []

        list.reserveCapacity(
            headings.count + 1 + breakdown.addends.count + breakdown.factors.count
        )

        for heading: ColorText in headings {
            list.append(
                .init(
                    fulfilled: nil,
                    highlight: true,
                    description: heading,
                    indent: 0
                )
            )
        }

        let base: ConditionListItem = .init(
            fulfilled: nil,
            highlight: false,
            description: "Base chance: \(em: breakdown.base[%])",
            indent: 0
        )

        list.append(base)

        list.add(nodes: breakdown.addends, indent: 1)
        list.add(nodes: breakdown.factors, indent: 0)

        return list
    }

    private mutating func add(nodes: [ConditionBreakdown.Node], indent: Int = 0) {
        for node: ConditionBreakdown.Node in nodes {
            self.append(
                .init(
                    fulfilled: node.listItem.fulfilled,
                    highlight: node.listItem.highlight,
                    description: node.listItem.description,
                    indent: indent
                )
            )
            self.add(nodes: node.children, indent: indent + 1)
        }
    }
}
