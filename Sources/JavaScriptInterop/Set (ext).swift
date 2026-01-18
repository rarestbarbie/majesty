extension Set: ConvertibleToJSArray, @retroactive ConvertibleToJSValue
    where Element: ConvertibleToJSValue {
}
