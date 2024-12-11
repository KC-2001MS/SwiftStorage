//
//  StorageManager.swift
//  SwiftStorage
//
//  Created by 茅根啓介 on 2024/12/11.
//

import Foundation

public class StorageManager {
    var type: StorageType
    
    var key: String
    
    public init(type: StorageType, key: String) {
        self.type = type
        self.key = key
    }
    
    public func set<T: Storable>(value: T) {
        switch type {
        case .local:
            UserDefaults.standard.set(value, forKey: key)
        case .localWith(let suite):
            UserDefaults(suiteName: suite)?.set(value, forKey: key)
//        case .cloud:
//            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        }
    }
    
    public func set<T: Codable>(value: T) {
        let data = try? JSONEncoder().encode(value)
        switch type {
        case .local:
            UserDefaults.standard.set(data, forKey: key)
        case .localWith(let suite):
            UserDefaults(suiteName: suite)?.set(data, forKey: key)
//        case .cloud:
//            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        }
    }
    
    public func get<T: Storable>(defaultValue: T) -> T {
        switch type {
        case .local:
            return UserDefaults.standard.value(forKey: key) as? T ?? defaultValue
        case .localWith(let suite):
            return UserDefaults(suiteName: suite)?.value(forKey: key) as? T ?? defaultValue
//        case .cloud:
//            return NSUbiquitousKeyValueStore.default.value(forKey: key) as? T ?? defaultValue
        }
    }
    
    public func get<T: Codable>(defaultValue: T) -> T {
        let data: Data
        switch type {
        case .local:
            data = UserDefaults.standard.value(forKey: key) as? Data ?? Data()
        case .localWith(let suite):
            data = UserDefaults(suiteName: suite)?.value(forKey: key) as? Data ?? Data()
//        case .cloud:
//            value = NSUbiquitousKeyValueStore.default.value(forKey: key) as? Data ?? Data()
        }
        
        let value = try? JSONDecoder().decode(T.self, from: data)
        return value ?? defaultValue
    }
}
