//
//  Storable.swift
//  SwiftStorage
//
//  Created by 茅根啓介 on 2024/12/11.
//


public protocol Storable {}

extension String: Storable {}
extension Int: Storable {}
extension Double: Storable {}
extension Float: Storable {}
extension Bool: Storable {}
extension Data: Storable {}
extension Array: Storable where Element: Storable {}
extension Dictionary: Storable where Key == String, Value: Storable {}
extension Date: Storable {}
