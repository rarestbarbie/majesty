import GameIDs
import JavaScriptInterop

extension EconomicLedger {
    @StringUnion enum Industry: Hashable, Comparable {
        @tag("B") case building(BuildingType)
        @tag("F") case factory(FactoryType)
        @tag("P") case slavery(CultureID)
        @tag("R") case artisan(Resource)
    }
}
extension EconomicLedger.Industry: CustomStringConvertible, LosslessStringConvertible {}
extension EconomicLedger.Industry: ConvertibleToJSString, LoadableFromJSString {}
