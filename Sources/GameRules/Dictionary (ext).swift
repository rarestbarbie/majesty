import GameIDs

extension [CultureID: Culture] {
    @inlinable public subscript(defined id: CultureID) -> Culture {
        get throws {
            guard let culture: Culture = self[id] else {
                throw CultureError.undefined(id)
            }
            return culture
        }
    }
}
