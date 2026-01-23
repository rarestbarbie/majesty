import Lexic
import SwiftSyntax
import SwiftSyntaxMacros

enum StringUnionMacro {}

extension StringUnionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        guard let decl: EnumDeclSyntax = decl.as(EnumDeclSyntax.self) else {
            context[.error, decl] = "@StringUnion must be applied to an enum"
            return []
        }

        let cases: [Case] = self.cases(of: decl, in: context)

        /// Note: `borrowing` is inserted, which is meaningful if the value is a ``String`` or
        /// some other allocated type, as `init`s default to `__owned`.
        let initializer: DeclSyntax = """
        @inlinable \(decl.modifiers)init?(_ $string: borrowing some StringProtocol) {
            guard
            let first: String.Index = $string.unicodeScalars.indices.first,
            let type: \(raw: decl.name.text)Type = .init(
                rawValue: $string.unicodeScalars[first]
            ) else {
                return nil
            }

            let next: String.Index = $string.unicodeScalars.index(after: first)

            switch type {\(
            raw: cases.map {
                if let payload: TypeSyntax = $0.type {
                    // separate binding needed in case the initializer is actually non-failable
                    return """
                    case .\($0.name):
                        let value: \(payload)? = .init($string[next...])
                        guard
                        let value: \(payload) else {
                            return nil
                        }
                        self = .\($0.name)(value)
                    """
                } else {
                    return """
                    case .\($0.name):
                        self = .\($0.name)
                    """
                }
            }.joined(separator: "\n")
        )
            }
        }
        """

        let type: DeclSyntax = """
        @inlinable \(decl.modifiers)var type: \(raw: decl.name.text)Type {
            switch self {\(
            raw: cases.map { "case .\($0.name): .\($0.name)" }.joined(separator: "\n")
        )
            }
        }
        """

        let description: DeclSyntax = """
        @inlinable \(decl.modifiers)var description: String {
            switch self {\(
            raw: cases.map {
                if case _? = $0.type {
                    return """
                    case .\($0.name)(let self): "\($0.discriminant)\\(self)"
                    """
                } else {
                    return """
                    case .\($0.name): "\($0.discriminant)"
                    """
                }
            }.joined(separator: "\n")
        )
            }
        }
        """
        return [initializer, type, description]
    }
}
extension StringUnionMacro: PeerMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingPeersOf decl: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let decl: EnumDeclSyntax = decl.as(EnumDeclSyntax.self) else {
            context[.error, decl] = "@StringUnion must be applied to an enum"
            return []
        }

        let cases: [Case] = self.cases(of: decl, in: context)
        let discriminant: DeclSyntax = """
        @frozen public enum \(raw: decl.name.text)Type: Unicode.Scalar {
        \(
            raw: cases.map {
                """
                    case \($0.name) = "\($0.discriminant)"\n
                """
            }.joined()
        )}
        """
        return [discriminant]
    }
}
extension StringUnionMacro {
    private static func cases(
        of decl: EnumDeclSyntax,
        in context: some MacroExpansionContext
    ) -> [Case] {
        decl.memberBlock.members.reduce(into: []) {
            guard let group: EnumCaseDeclSyntax = $1.decl.as(EnumCaseDeclSyntax.self) else {
                return
            }

            // find the `@tag` attribute
            var discriminant: Unicode.Scalar? = nil

            for case .attribute(let attribute) in group.attributes {
                let type: TypeSyntax = attribute.attributeName

                guard case .argumentList(let arguments) = attribute.arguments,
                let identifier: IdentifierTypeSyntax = type.as(IdentifierTypeSyntax.self),
                    identifier.name.text == "tag",
                let letter: ExprSyntax = arguments.first?.expression,
                let letter: StringLiteralExprSyntax = letter.as(StringLiteralExprSyntax.self),
                case .stringSegment(let letter)? = letter.segments.first else {
                    continue
                }

                discriminant = letter.content.text.unicodeScalars.first
                break
            }

            // b. Extract the discriminant character from the attribute.
            guard
            let discriminant: Unicode.Scalar else {
                context[.error, $1] = "enum case is missing required '@tag' attribute"
                return
            }

            for element: EnumCaseElementSyntax in group.elements {
                if  let payload: EnumCaseParameterClauseSyntax = element.parameterClause,
                        payload.parameters.count > 1 {
                    context[.error, payload] = "enum case may contain at most one payload"
                    return
                }

                $0.append(
                    .init(
                        name: element.name.text,
                        type: element.parameterClause?.parameters.first?.type.trimmed,
                        discriminant: discriminant,
                    )
                )
            }
        }
    }
}
