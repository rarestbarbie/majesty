import GameConditions
import GameIDs

extension PopContext {
    struct Converter: PopFactors {
        typealias Matrix = ConditionEvaluator

        let region: RegionalProperties
        let stats: Pop.Stats

        let type: PopType
        let y: Pop.Dimensions
        let z: Pop.Dimensions
    }
}
