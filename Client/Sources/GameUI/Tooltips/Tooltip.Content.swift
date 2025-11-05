extension Tooltip {
    @frozen @usableFromInline enum Content {
        case instructions([TooltipInstruction])
        case conditions([[ConditionListItem]])
    }
}
