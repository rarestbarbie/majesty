@Identifier(Int32.self) @frozen public struct MineID: GameID {}

extension MineID {
    @inlinable public static func / (self: Self, vein: Resource) -> MineVein {
        .init(mine: self, resource: vein)
    }
}
