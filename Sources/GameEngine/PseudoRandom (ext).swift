import JavaScriptKit
import JavaScriptInterop
import Random

extension PseudoRandom: LoadableFromJSValue,
    @retroactive ConstructibleFromJSValue,
    @retroactive ConvertibleToJSValue {
}
