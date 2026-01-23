import ArgumentParser
import GameIDs

extension GameDate: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
