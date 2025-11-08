import GameIDs

enum WorkforceChanges {
    case hire(PopType, PopJobOfferBlock)
    case fire(PopType, PopJobLayoffBlock)
}
