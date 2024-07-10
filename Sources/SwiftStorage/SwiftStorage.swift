//
//  SwiftStorage.swift
//
//
//  Created by Keisuke Chinone on 2024/07/06.
//


// The Swift Programming Language
// https://docs.swift.org/swift-book
#if canImport(Observation) && canImport(Foundation)
import Observation
import Foundation

@attached(member, names: named(_$id), named(_$observationRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
@attached(extension, conformances: Observable)
public macro Storage() = #externalMacro(module: "SwiftStorageMacros", type: "StorageMacro")


@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro LocalStorageProperty() = #externalMacro(module: "SwiftStorageMacros", type: "LocalStoragePropertyMacro")


@attached(accessor, names: named(willSet))
public macro Transient() = #externalMacro(module: "SwiftStorageMacros", type: "TransientMacro")
#endif
