//
//  SwiftStoragePlugin.swift
//  
//  
//  Created by Keisuke Chinone on 2024/07/07.
//


import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SwiftStoragePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StorageMacro.self,
        LocalStoragePropertyMacro.self,
        TransientMacro.self,
        AttributeMacro.self,
    ]
}
