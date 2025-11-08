@attached(
    member,
    names: named(rawValue), named(init(rawValue:))
) public macro Identifier<T>(
    _ type: T.Type
) = #externalMacro(module: "GameStateMacros", type: "IdentifierMacro")

@attached(peer, names: suffixed(Type))
@attached(
    member,
    names: named(description), named(type), named(init(_:)),
    conformances: LosslessStringConvertible
) public macro StringUnion(
) = #externalMacro(module: "GameStateMacros", type: "StringUnionMacro")

@attached(peer) public macro tag(_ code: Unicode.Scalar) = #externalMacro(
    module: "GameStateMacros",
    type: "StringUnionMacro.Case"
)
