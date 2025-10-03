import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that synthesizes the core implementation for a type-safe,
/// `RawRepresentable` identifier.
///
/// This macro takes a single, unlabeled argument specifying the type of the
/// underlying raw value. It generates a `public var rawValue` stored property
/// and a public, inlinable `init(rawValue:)` initializer.
///
/// Example:
/// ```swift
/// @Identifier(Int32.self) @frozen public struct PlanetID: GameID {}
/// ```
public struct IdentifierMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
        let arguments: LabeledExprListSyntax = node.arguments?.as(LabeledExprListSyntax.self),
        let argument: LabeledExprSyntax = arguments.first,
        case nil = argument.label,
        let type: MemberAccessExprSyntax = argument.expression.as(MemberAccessExprSyntax.self),
        let type: ExprSyntax = type.base
        else {
            fatalError("expected a single, unlabeled argument specifying the raw value type")
        }

        let property: DeclSyntax = "public var rawValue: \(type)"
        let initializer: DeclSyntax =
        """
        @inlinable public init(rawValue: \(type)) {
            self.rawValue = rawValue
        }
        """

        return [property, initializer]
    }
}
