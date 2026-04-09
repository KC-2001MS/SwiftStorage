//
//  StorageType.swift
//  SwiftStorage
//
//  Created by 茅根啓介 on 2024/12/11.
//

public enum StorageType {
    case local
    case localWith(suite: String?)
    case cloud

    public var backend: any StorageBackend {
        switch self {
        case .local:
            return UserDefaults.standard
        case .localWith(let suite):
            if let suite {
                return UserDefaults(suiteName: suite) ?? .standard
            }
            return UserDefaults.standard
        case .cloud:
            return NSUbiquitousKeyValueStore.default
        }
    }
}

/// Options for customizing storage attribute behavior
public enum StorageAttributeOption {
    /// The property is observed but not persisted to storage.
    /// Equivalent to SwiftData's `Schema.Attribute.Option.ephemeral`.
    case ephemeral
}
