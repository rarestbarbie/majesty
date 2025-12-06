import GameIDs

@frozen public struct Legend {
    public let occupation: [PopOccupation: Representation]
    public let gender: [Gender: Representation]
}
