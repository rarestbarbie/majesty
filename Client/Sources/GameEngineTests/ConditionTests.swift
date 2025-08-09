import GameEngine
import Testing

@Suite struct ConditionTests {
    @Test static func Empty() {
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: { _ in
        }

        #expect(evaluator.output == 0.01)

        let tooltip: ConditionBreakdown = .init(base: 1%) { _ in
        } factors: { _ in
        }

        #expect(tooltip.output == 0.01)
    }

    @Test static func Addends() {
        let x: Float = 0.5
        let evaluator: ConditionEvaluator = .init(base: 1%) {
            $0[x] { $0[$1 < 0.5] = 1‰ } = { "X is less than \($1)" }
            $0[x] { $0[$1 == 0.5] = 2‰ } = { "X is equal to \($1)" }
            $0[x] { $0[$1 > 0.5] = 5‰ } = { "X is greater than \($1)" }
        } factors: { _ in
        }

        #expect(evaluator.output == 0.012)
    }

    @Test static func AddendsStacking() {
        let x: Float = 0.51
        let evaluator: ConditionEvaluator = .init(base: 1%) {
            $0[x] {
                $0[$1 >= 0.1] = 1‰
                $0[$1 >= 0.2] = 2‰
                $0[$1 >= 0.3] = 3‰
                $0[$1 >= 0.4] = 4‰
                $0[$1 >= 0.5] = 5‰
                $0[$1 >= 0.6] = 6‰
            } = { "X is at least \($1)" }
        } factors: { _ in
        }

        #expect(evaluator.output == 0.025)

        let tooltip: ConditionBreakdown = .init(base: 1%) {
            $0[x] {
                $0[$1 >= 0.1] = 1‰
                $0[$1 >= 0.2] = 2‰
                $0[$1 >= 0.3] = 3‰
                $0[$1 >= 0.4] = 4‰
                $0[$1 >= 0.5] = 5‰
                $0[$1 >= 0.6] = 6‰
            } = { "X is at least \($1)" }
        } factors: { _ in
        }

        #expect(tooltip.output == 0.025)
        #expect(tooltip.addends == [
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "X is at least 0.5",
                    ),
                    children: []
                ),
            ]
        )
    }

    @Test static func AddendsMultiple() {
        let x: Float = 0.51
        let y: Float = 2.5
        let z: Float = 0.1
        let evaluator: ConditionEvaluator = .init(base: 1%) {
            $0[x] {
                $0[$1 >= 0.1] = 1‰
            } = { "X is at least \($1)" }
            $0[y] {
                $0[$1 >= 2.0] = 3‰
            } = { "Y is at least \($1)" }
            $0[z] {
                $0[$1 >= 1.0] = 5‰
            } = { "Z is at least \($1)" }
        } factors: { _ in
        }

        #expect(evaluator.output == 0.014)

        let tooltip: ConditionBreakdown = .init(base: 1%) {
            $0[x] {
                $0[$1 >= 0.1] = 1‰
            } = { "X is at least \($1)" }
            $0[y] {
                $0[$1 >= 2.0] = 3‰
            } = { "Y is at least \($1)" }
            $0[z] {
                $0[$1 >= 1.0] = 5‰
            } = { "Z is at least \($1)" }
        } factors: { _ in
        }

        #expect(tooltip.output == 0.014)
        #expect(tooltip.addends == [
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "X is at least 0.1",
                    ),
                    children: []
                ),
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "Y is at least 2.0",
                    ),
                    children: []
                ),
                .init(
                    listItem: .init(
                        fulfilled: false,
                        highlight: true,
                        description: "Z is at least 1.0",
                    ),
                    children: []
                ),
            ]
        )
    }

    @Test static func Factors() {
        let x: Float = 0.51
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[x] {
                $0[$1 >= 0.1] = +50%
            } = { "X is at least \($1)" }
        }

        // Floating point arithmetic can lead to small inaccuracies, so we use a tolerance.
        #expect(abs(evaluator.output - 0.015) <= 1e-17)
    }
    @Test static func FactorsMultiple() {
        let x: Float = 0.51
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[x] {
                $0[$1 >= 0.1] = -50%
            } = { "X is at least \($1)" }
            $0[x] {
                $0[$1 >= 0.2] = -50%
            } = { "X is at least \($1)" }
        }

        #expect(abs(evaluator.output - 0.0025) <= 1e-17)
    }
    @Test static func FactorsZero() {
        let x: Float = 0.51
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[x] {
                $0[$1 >= 0.1] = -100%
            } = { "X is at least \($1)" }
        }

        #expect(evaluator.output == 0.0)
    }
    @Test static func FactorsOverkill() {
        let x: Float = 0.51
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[x] {
                $0[$1 >= 0.1] = -200%
            } = { "X is at least \($1)" }
            $0[x] {
                $0[$1 >= 0.2] = -200%
            } = { "X is at least \($1)" }
        }

        #expect(evaluator.output == 0.0)

        let tooltip: ConditionBreakdown = .init(base: 1%) { _ in
        } factors: {
            $0[x] {
                $0[$1 >= 0.1] = -200%
            } = { "X is at least \($1)" }
            $0[x] {
                $0[$1 >= 0.2] = -200%
            } = { "X is at least \($1)" }
        }

        #expect(tooltip.output == 0.0)
        #expect(tooltip.addends == [])
        #expect(tooltip.factors == [
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "X is at least 0.1",
                    ),
                ),
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "X is at least 0.2",
                    ),
                ),
            ]
        )
    }

    @Test static func AnySatisfy() {
        let x: Float = 0.51
        let y: Float = 1.01
        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[any: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 0.1 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[any: true] {
                $0 = +50%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[any: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 1.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }
        }

        #expect(abs(evaluator.output - 0.04) <= 1e-17)

        let tooltip: ConditionBreakdown = .init(base: 1%) { _ in
        } factors: {
            $0[any: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 0.1 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[any: true]  {
                $0 = +50%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[any: true]  {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 1.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }
        }

        #expect(abs(tooltip.output - 0.04) <= 1e-17)
        #expect(tooltip.addends == [])
        #expect(tooltip.factors == [
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "+100%: Any of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: true,
                                description: "X is at least 0.1",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: false,
                                description: "Y is at least 9.0",
                            ),
                            children: []
                        ),
                    ]
                ),
                .init(
                    listItem: .init(
                        fulfilled: false,
                        highlight: true,
                        description: "+50%: Any of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: false,
                                description: "X is at least 9.0",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: false,
                                description: "Y is at least 9.0",
                            ),
                            children: []
                        ),
                    ]
                ),
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "+100%: Any of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: false,
                                description: "X is at least 9.0",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: true,
                                description: "Y is at least 1.0",
                            ),
                            children: []
                        ),
                    ]
                ),
            ]
        )
    }

    @Test static func AllSatisfy() {
        let x: Float = 0.51
        let y: Float = 1.01

        let evaluator: ConditionEvaluator = .init(base: 1%) { _ in
        } factors: {
            $0[all: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 0.1 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +50%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 1.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +25%
            } when: {
                $0[x] { $1 >= 0.5 } = { "X is at least \($1)" }
                $0[y] { $1 >= 0.5 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }
        }

        #expect(abs(evaluator.output - 0.0125) <= 1e-17)

        let tooltip: ConditionBreakdown = .init(base: 1%) { _ in
        } factors: {
            $0[all: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 0.1 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +50%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 9.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +100%
            } when: {
                $0[x] { $1 >= 9.0 } = { "X is at least \($1)" }
                $0[y] { $1 >= 1.0 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }

            $0[all: true] {
                $0 = +25%
            } when: {
                $0[x] { $1 >= 0.5 } = { "X is at least \($1)" }
                $0[y] { $1 >= 0.5 } = { "Y is at least \($1)" }
            } = { "\(+$0[%]): \($1)" }
        }

        #expect(abs(tooltip.output - 0.0125) <= 1e-17)
        #expect(tooltip.addends == [])
        #expect(tooltip.factors == [
                .init(
                    listItem: .init(
                        fulfilled: false,
                        highlight: true,
                        description: "+100%: All of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: false,
                                description: "X is at least 0.1",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: true,
                                description: "Y is at least 9.0",
                            ),
                            children: []
                        ),
                    ]
                ),
                .init(
                    listItem: .init(
                        fulfilled: false,
                        highlight: true,
                        description: "+50%: All of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: true,
                                description: "X is at least 9.0",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: true,
                                description: "Y is at least 9.0",
                            ),
                            children: []
                        ),
                    ]
                ),
                .init(
                    listItem: .init(
                        fulfilled: false,
                        highlight: true,
                        description: "+100%: All of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: false,
                                highlight: true,
                                description: "X is at least 9.0",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: false,
                                description: "Y is at least 1.0",
                            ),
                            children: []
                        ),
                    ]
                ),
                .init(
                    listItem: .init(
                        fulfilled: true,
                        highlight: true,
                        description: "+25%: All of the following",
                    ),
                    children: [
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: false,
                                description: "X is at least 0.5",
                            ),
                            children: []
                        ),
                        .init(
                            listItem: .init(
                                fulfilled: true,
                                highlight: false,
                                description: "Y is at least 0.5",
                            ),
                            children: []
                        ),
                    ]
                ),
            ]
        )
    }

    @Test(
        arguments: [
            (mil: 0.1, con: 9.9, expected: 0.05),
            (mil: 0.1, con: 8.9, expected: 0.01),
            (mil: 2.0, con: 2.0, expected: 0.02),
            (mil: 8.0, con: 8.0, expected: 0.02),
            (mil: 6.0, con: 6.0, expected: 0.01),
        ]
    )
    static func NestedLogic(_ mil: Double, _ con: Double, _ expected: Double) {
        let tooltip: ConditionBreakdown = .init(base: 1%) {
            $0[any: true] {
                $0 = +1%
            } when: {
                $0[all: true] {
                    $0[mil] { $1 < 5.0 } = { "Militancy is below \($1[..1])" }
                    $0[con] { $1 < 5.0 } = { "Consciousness is below \($1[..1])" }
                }
                $0[all: true] {
                    $0[mil] { $1 > 7.0 } = { "Militancy is above \($1[..1])" }
                    $0[con] { $1 > 7.0 } = { "Consciousness is above \($1[..1])" }
                }
            } = { "\(+$0[%2]): \($1)" }

        } factors: {
            $0[all: true] {
                $0 = +400%
            } when: {
                $0[any: true] {
                    $0[mil] { $1 < 1.0 } = { "Militancy is below \($1[..1])" }
                    $0[mil] { $1 > 9.0 } = { "Consciousness is above \($1[..1])" }
                }
                $0[any: true] {
                    $0[con] { $1 < 1.0 } = { "Militancy is below \($1[..1])" }
                    $0[con] { $1 > 9.0 } = { "Consciousness is above \($1[..1])" }
                }
            } = { "\(+$0[%2]): \($1)" }
        }

        #expect(abs(tooltip.output - expected) <= 1e-17)
    }
}
