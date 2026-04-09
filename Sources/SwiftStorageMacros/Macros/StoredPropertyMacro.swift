//
//  PersistedPropertyMacro.swift
//  
//  
//  Created by Keisuke Chinone on 2024/07/06.
//


import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntaxBuilder

public struct StoredPropertyMacro: AccessorMacro {
    public static func expansion<
        Context: MacroExpansionContext,
        Declaration: DeclSyntaxProtocol
    >(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation,
              let identifier = property.identifier?.trimmed 
        else {
            return []
        }
        
        if property.hasMacroApplication(StorageMacro.transientMacroName) {
            return []
        }
        
        guard let binding = property.bindings.first,
              let _ = binding.typeAnnotation?.type.identifier
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(property),
                    message: StorageDiagnostic(
                        message: "stored property '\(identifier.text)' requires an explicit type annotation to be persisted by '@Storage'",
                        domain: "SwiftStorage",
                        id: .missingTypeAnnotation
                    ),
                    notes: [
                        Note(
                            node: Syntax(property),
                            message: StorageNoteMessage(
                                message: "add a type annotation, e.g. 'var \(identifier.text): <Type>'",
                                id: "add-type-annotation"
                            )
                        )
                    ]
                )
            )
            return []
        }
        
        
        // Find enclosing type name from lexical context for compile-time literal key
        let enclosingTypeName = context.lexicalContext.lazy.compactMap { syntax -> String? in
            if let classDecl = syntax.as(ClassDeclSyntax.self) {
                return classDecl.name.text
            }
            return nil
        }.first

        var key: String
        if let enclosingTypeName {
            key = "\(enclosingTypeName).\(identifier.text)"
        } else {
            key = "\\(className).\(identifier)"
        }

        var storageType: String = ".local"

        // Read class default storage type from @_StoredProperty(type:) node arguments
        if case .argumentList(let args) = node.arguments {
            for arg in args {
                if let label = arg.label?.text, label == "type" {
                    storageType = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        if property
            .hasMacroApplication(StorageMacro.attributeMacroName), let text = property.attributeStringValue(
                for: "key"
            ) {
            key = text
        }

        // Check if @Attribute(type:) overrides class default
        let hasAttributeTypeOverride = property.hasMacroApplication(StorageMacro.attributeMacroName)
            && property.attributeTypeValue(for: "type") != nil

        if hasAttributeTypeOverride,
           let text = property.attributeTypeValue(for: "type") {
            storageType = text
        }

        // Determine whether to hash the key (class default from @_StoredProperty(hashed:), then @Attribute(hashed:) override)
        var hashed = true
        if case .argumentList(let args) = node.arguments {
            for arg in args {
                if let label = arg.label?.text, label == "hashed",
                   let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self) {
                    hashed = boolLiteral.literal.tokenKind == .keyword(.true)
                }
            }
        }
        if property.hasMacroApplication(StorageMacro.attributeMacroName),
           let hashedValue = property.attributeBoolValue(for: "hashed") {
            hashed = hashedValue
        }

        let keyExpression: String
        if hashed {
            keyExpression = "#hashify(\"\(key)\")"
        } else {
            keyExpression = "\"\(key)\""
        }

        let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = initialValue
      }
      """

        // Use _$store_<propertyName> if @Attribute(type:) overrides, otherwise _$store
        let storageBackend = hasAttributeTypeOverride ? "_$store_\(identifier.text)" : "_$store"
        let cloudSyncCall = storageType == ".cloud" ? "\n_$startCloudSync()" : ""

        let getAccessor: AccessorDeclSyntax =
      """
      get {\(raw: cloudSyncCall)
      access(keyPath: \\.\(identifier))
      return \(raw: storageBackend).persistedValue(forKey: \(raw: keyExpression), default: _\(identifier))
      }
      """

        let setAccessor: AccessorDeclSyntax =
      """
      set {
      if shouldNotifyObservers(\(raw: storageBackend).persistedValue(forKey: \(raw: keyExpression), default: _\(identifier)), newValue) {
      withMutation(keyPath: \\.\(identifier)) {
      \(raw: storageBackend).setPersisted(newValue, forKey: \(raw: keyExpression))
      }
      }
      }
      """
        
        let modifyAccessor: AccessorDeclSyntax =
      """
      _modify {
      access(keyPath: \\.\(identifier))
      \(raw: StorageMacro.registrarVariableName).willSet(self, keyPath: \\.\(identifier))
      var value = \(raw: storageBackend).persistedValue(forKey: \(raw: keyExpression), default: _\(identifier))
      defer {
      \(raw: storageBackend).setPersisted(value, forKey: \(raw: keyExpression))
      \(raw: StorageMacro.registrarVariableName).didSet(self, keyPath: \\.\(identifier))
      }
      yield &value
      }
      """
        
        return [initAccessor, getAccessor, setAccessor, modifyAccessor]
    }

}

extension StoredPropertyMacro: PeerMacro {
    public static func expansion<
        Context: MacroExpansionContext,
        Declaration: DeclSyntaxProtocol
    >(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation else {
            return []
        }
        
        if property.hasMacroApplication(StorageMacro.transientMacroName) ||
            property
            .hasMacroApplication(StorageMacro.observationIgnoredMacroName) ||
            property
            .hasMacroApplication(StorageMacro.storedPropertyMacroName) ||
            property
            .hasMacroApplication(StorageMacro.observationTrackedMacroName) {
            return []
        }
        
        let storage = DeclSyntax(
            property
                .privatePrefixed(
                    "_",
                    addingAttribute: StorageMacro.ignoredAttribute
                )
        )
        return [storage]
    }
}

extension VariableDeclSyntax {
    func attributeStringValue(for key: String) -> String? {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                // 属性名が目的のものか確認
                if attr.attributeName
                    .tokens(viewMode: .all)
                    .map({ $0.tokenKind }) == [.identifier(
                        StorageMacro.attributeMacroName
                    )] {
                    switch attr.arguments {
                    case .argumentList(let args):
                        // 引数リストから目的のキーに一致する値を検索
                        for arg in args {
                            if arg.label?.text == key {
                                return arg.expression
                                    .as(
                                        StringLiteralExprSyntax.self
                                    )?.segments.first?
                                    .as(StringSegmentSyntax.self)?.content.text
                            }
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        return nil
    }
    
    func attributeTypeValue(for key: String) -> String? {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName
                    .tokens(viewMode: .all)
                    .map({ $0.tokenKind }) == [.identifier(
                        StorageMacro.attributeMacroName
                    )] {
                    switch attr.arguments {
                    case .argumentList(let args):
                        for arg in args {
                            if let label = arg.label?.text, label == "type" {
                                return arg.expression.description.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                            }
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        return nil
    }

    func attributeBoolValue(for key: String) -> Bool? {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName
                    .tokens(viewMode: .all)
                    .map({ $0.tokenKind }) == [.identifier(
                        StorageMacro.attributeMacroName
                    )] {
                    switch attr.arguments {
                    case .argumentList(let args):
                        for arg in args {
                            if arg.label?.text == key,
                               let boolLiteral = arg.expression.as(BooleanLiteralExprSyntax.self) {
                                return boolLiteral.literal.tokenKind == .keyword(.true)
                            }
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        return nil
    }
}
