//
//  StorageManager.swift
//  SwiftStorage
//
//  Created by 茅根啓介 on 2024/12/11.
//

import Foundation

public protocol StorageBackend: AnyObject {
    func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T
    func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T
    func setPersisted<T: Storable>(_ value: T, forKey key: String)
    func setPersisted<T: Codable>(_ value: T, forKey key: String)
}

extension UserDefaults: StorageBackend {}
extension NSUbiquitousKeyValueStore: StorageBackend {}

extension UserDefaults {
    public func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T {
        value(forKey: key) as? T ?? defaultValue
    }

    public func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = value(forKey: key) as? Data else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    public func setPersisted<T: Storable>(_ value: T, forKey key: String) {
        set(value, forKey: key)
    }

    public func setPersisted<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
}

extension NSUbiquitousKeyValueStore {
    public func persistedValue<T: Storable>(forKey key: String, default defaultValue: T) -> T {
        object(forKey: key) as? T ?? defaultValue
    }

    public func persistedValue<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = data(forKey: key) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    public func setPersisted<T: Storable>(_ value: T, forKey key: String) {
        set(value, forKey: key)
    }

    public func setPersisted<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
}
