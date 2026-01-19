extension ArraySlice: ConvertibleToJSArray, @retroactive ConvertibleToJSValue
    where Element: ConvertibleToJSValue {
}
