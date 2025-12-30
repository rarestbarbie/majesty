import GameIDs
import GameState
import Random

struct LaborMarket: ~Copyable {
    private var region: Supply<Regionwide>
    private var planet: Supply<Planetwide>
}
extension LaborMarket {
    static func index(
        pops: DynamicContextTable<PopContext>,
        in order: GameContext.ResidentOrder
    ) -> Self {
        let supply: (
            region: [Regionwide: [(Int, Int64)]],
            planet: [Planetwide: [(Int, Int64)]]
        ) = order.residents.reduce(into: ([:], [:])) {
            guard case .pop(let i) = $1 else {
                return
            }

            let pop: PopContext = pops[i]
            let mode: PopOccupation.Mode = pop.state.occupation.mode

            // early exit for pops that do not participate in hiring
            switch mode {
            case .aristocratic: return
            case .livestock: return
            case .remote: break
            case .hourly: break
            case .mining: break
            }

            guard
            let currency: CurrencyID = pop.region?.properties.currency.id else {
                return
            }

            let unemployed: Int64 = pop.state.z.active - pop.state.employed()
            if  unemployed <= 0 {
                return
            }

            if case .remote = mode {
                let key: Planetwide = .init(
                    id: pop.state.tile.planet,
                    bloc: currency,
                    type: pop.state.occupation
                )
                $0.planet[key, default: []].append((i, unemployed))
            } else {
                let key: Regionwide = .init(
                    id: pop.state.tile,
                    type: pop.state.occupation
                )
                $0.region[key, default: []].append((i, unemployed))
            }
        }

        return .init(
            region: .init(pops: supply.region),
            planet: .init(pops: supply.planet),
        )
    }

    consuming func match(
        region: inout LaborMarket.Demand<LaborMarket.Regionwide>,
        planet: inout LaborMarket.Demand<LaborMarket.Planetwide>,
        random: PseudoRandom,
        mode: LaborMarketPolicy,
        post: (PopJobOffer, Int, Int64) -> ()
    ) -> (
        [(PopOccupation, [PopJobOfferBlock])],
        [(PopOccupation, [PopJobOfferBlock])]
    ) {
        // iteration order is non-deterministic, so we need to use a local RNG
        let workersUnavailable: [(PopOccupation, [PopJobOfferBlock])] = region.turn {
            if  let pops: LaborMarket.Sampler = self.region.pull($0) {
                pops.match(offers: &$1, random: random, mode: mode, post: post)
            }
        }
        let clerksUnavailable: [(PopOccupation, [PopJobOfferBlock])] = planet.turn {
            if  let pops: LaborMarket.Sampler = self.planet.pull($0) {
                pops.match(offers: &$1, random: random, mode: mode, post: post)
            }
        }
        return (workersUnavailable, clerksUnavailable)
    }
}
