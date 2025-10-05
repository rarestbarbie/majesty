import GameState
import Testing

@Suite struct GameDateTests {
    @Test func Comparisons() {
        let date: GameDate = .gregorian(year: 2023, month: 10, day: 5)
        let date2: GameDate = .gregorian(year: 2023, month: 10, day: 5)
        let date3: GameDate = .gregorian(year: 2024, month: 10, day: 5)
        let date4: GameDate = .gregorian(year: 2023, month: 11, day: 5)
        let date5: GameDate = .gregorian(year: 2023, month: 10, day: 6)

        #expect(date == date2)
        #expect(date != date3)
        #expect(date != date4)
        #expect(date != date5)

        #expect(date < date3)
        #expect(date < date4)
        #expect(date < date5)

        #expect(date <= date2)
        #expect(date <= date3)
        #expect(date <= date4)
        #expect(date <= date5)

        #expect(date >= date2)
    }

    @Test(
        arguments: [
            .gregorian(year: 0, month: 1, day: 1),
            .gregorian(year: 2023, month: 10, day: 5),
            .gregorian(year: 2023, month: 10, day: 6),
            .gregorian(year: 2023, month: 11, day: 5),
            .gregorian(year: 2023, month: 12, day: 31),
            .gregorian(year: 2024, month: 2, day: 29),
            .gregorian(year: 4000, month: 1, day: 1),
        ] as [GameDate]
    ) static func Roundtrip(_ date: GameDate) {
        let new: (year: Int32, month: Int32, day: Int32) = date.gregorian
        #expect(date == .gregorian(year: new.year, month: new.month, day: new.day))
    }
}
