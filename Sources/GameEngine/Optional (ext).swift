extension Optional where Wrapped: Comparable {
    /// Sorts two optionals, treating `nil` as greater than any value.
    @inlinable static func <? (a: Self, b: Self) -> Bool {
        switch (a, b) {
        case (let a?, let b?): a < b
        case (_?, nil):  true
        case (nil, _?):  false
        case (nil, nil): false
        }
    }

    /// Sorts two optionals, treating `nil` as less than any value.
    @inlinable static func ?< (a: Self, b: Self) -> Bool {
        switch (a, b) {
        case (let a?, let b?): a < b
        case (nil, _?):  true
        case (_?, nil):  false
        case (nil, nil): false
        }
    }
}
