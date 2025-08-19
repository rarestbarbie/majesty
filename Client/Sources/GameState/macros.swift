@attached(member, names: named(rawValue), named(init(rawValue:)))
public macro Identifier<T>(
    _ type: T.Type
) = #externalMacro(module: "GameStateMacros", type: "IdentifierMacro")
