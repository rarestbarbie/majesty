import GameIDs
import GameRules
import GameStarts

extension GameStart {
    struct Symbols {
        let `static`: GameSaveSymbols
        let cultures: SymbolTable<CultureID>
    }
}
extension GameStart.Symbols {
    init(static: GameSaveSymbols, cultures: [CultureSeed]) {
        self.static = `static`

        var culture: CultureID = GameStart.highest(in: cultures)
        let cultures: [Symbol: CultureID] = cultures.reduce(into: [:]) {
            $0[$1.name] = $1.id ?? culture.increment()
        }

        self.cultures = .init(index: cultures)
    }
}
