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
              let type = binding.typeAnnotation?.type.identifier
        else {
            return []
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
      return UserDefaults.standard.value(forKey: "\(identifier)") as? \(raw: type) ?? _\(identifier)
      }
      """
        
        let setAccessor: AccessorDeclSyntax =
      """
      set {
      withMutation(keyPath: \\.\(identifier)) {
      UserDefaults.standard.set(newValue, forKey: "\(identifier)")
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
            property.hasMacroApplication(StorageMacro.trackedMacroName) {
            return []
        }
        
        let storage = DeclSyntax(property.privatePrefixed("_", addingAttribute: StorageMacro.ignoredAttribute))
        return [storage]
    }
}
