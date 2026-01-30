import D
import GameUI

protocol BusinessSnapshot: LegalEntitySnapshot {
    associatedtype Terminology: AccountingTerminology
    associatedtype CashFlow: AccountingCashFlow
    var spending: CashFlow { get }
}
extension BusinessSnapshot {
    func explain(
        statement: FinancialStatement,
        account: Bank.Account,
        tooltip ul: inout TooltipInstructionEncoder
    ) {
        let profit: FinancialStatement.Profit = statement.profit
        let liquid: Delta<Int64> = account.Δ
        let assets: Delta<Int64> = self.Δ.assets

        ul["Total valuation", +] = (liquid + assets)[/3]
        ul[>] {
            $0["Today’s profit", +] = +profit.operating[/3]
            $0["Gross margin", +] = profit.grossMargin.map {
                (Double.init($0))[%2]
            }
            $0["Operating margin", +] = profit.operatingMargin.map {
                (Double.init($0))[%2]
            }
        }

        ul["Illiquid assets", +] = assets[/3]
        ul["Liquid assets", +] = liquid[/3]
        ul[>] {
            $0[Terminology.s, +] = +?account.s[/3]
            $0[Terminology.i, +] = +?account.i[/3]
            $0[Terminology.e, +] = +?account.e[/3]
            $0[Terminology.f, +] = +?account.f[/3]
            $0[Terminology.b, +] = +account.b[/3]
            $0[Terminology.c, +] = +?account.c[/3]
            $0[Terminology.d, +] = +?account.d[/3]
        }

        ul["Net income", +] = +(statement.incomeUnrealizedGain + account.i + account.s)[/3]
        ul[>] {
            $0["Revenue", +] = +?statement.lines.valueProduced[/3]
            $0["Materials", +] = +?(-statement.lines.valueConsumed)[/3]

            let cashFlow: CashFlow = self.spending

            $0["Interest and dividends", +] = +?(-cashFlow.dividend)[/3]
            $0["Salaries", +] = +?(-cashFlow.salaries)[/3]
            $0["Wages", +] = +?(-cashFlow.wages)[/3]
            $0["Subsidies", +] = +?account.s[/3]

            // debug canary, should never appear if our math is correct
            $0["FRAUD???", +] = +?(
                account.i + cashFlow.dividend + cashFlow.salaries + cashFlow.wages
            )[/3]
        }
    }
}
