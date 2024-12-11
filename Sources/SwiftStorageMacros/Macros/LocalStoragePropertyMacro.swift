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

public struct LocalStoragePropertyMacro: AccessorMacro {
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
            return []
        }
        
        
        var key = "\\(className).\(identifier)"
        
        var storageType: String = ".local"
        
        if property
            .hasMacroApplication(StorageMacro.attributeMacroName), let text = property.attributeStringValue(
                for: "key"
            ) {
            key = text
        }
        
        if property
            .hasMacroApplication(StorageMacro.attributeMacroName), let text = property.attributeTypeValue(
                for: "type"
            ) {
            storageType = text
        }
        
        let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = initialValue
      }
      """
        
        let getAccessor: AccessorDeclSyntax =
      """
      get {
      access(keyPath: \\.\(identifier))
      return StorageManager(type: \(raw: storageType), key: "\(raw: key)").get(defaultValue: _\(identifier))
      }
      """
        
        let setAccessor: AccessorDeclSyntax =
      """
      set {
      withMutation(keyPath: \\.\(identifier)) {
      StorageManager(type: \(raw: storageType), key: "\(raw: key)").set(value: newValue)
      _\(identifier) = newValue
      }
      }
      """
        
        let modifyAccessor: AccessorDeclSyntax =
      """
      _modify {
      access(keyPath: \\.\(identifier))
      \(raw: StorageMacro.registrarVariableName).willSet(self, keyPath: \\.\(identifier))
      defer { \(raw: StorageMacro.registrarVariableName).didSet(self, keyPath: \\.\(identifier)) }
      yield &_\(identifier)
      }
      """
        
        return [initAccessor, getAccessor, setAccessor, modifyAccessor]
    }
}

extension LocalStoragePropertyMacro: PeerMacro {
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
            .hasMacroApplication(StorageMacro.localStoragePropertyMacroName) ||
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
                            if let labeledExpr = arg.as(LabeledExprSyntax.self),
                               labeledExpr.label?.text == key {
                                
                                return labeledExpr.expression
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
                            if let label = arg.label?.text, label == "type" {
                                // mode 引数を解析
                                if let enumCaseExpr = arg.expression.as(
                                    MemberAccessExprSyntax.self
                                ) {
                                    // `.localWith(type: nil)` を文字列として取得
                                    let enumCaseString = enumCaseExpr.description.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                    return enumCaseString
                                }
                                
                                if let enumCaseExpr = arg.expression.as(
                                    FunctionCallExprSyntax.self
                                ) {
                                    // `.local` を文字列として取得
                                    let enumCaseString = enumCaseExpr.description.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                    return enumCaseString
                                }
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
