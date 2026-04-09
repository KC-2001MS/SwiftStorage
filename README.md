# SwiftStorage
SwiftStorage is an easy way to persist data without Key Value. And it is designed to integrate seamlessly with SwiftUI.

## Features
- [x] Support for Observation framework
- [x] Can be disabled on a per-property basis
- [x] Observation-only properties (no persistence)
- [x] Save in UserDefaults
- [x] Save in Key Value Store (iCloud)
- [x] Custom UserDefaults suites (e.g., App Groups)
- [x] Specify keys individually
- [x] Key hashing with [Hashify](https://github.com/KC-2001MS/Hashify) for security
- [x] Key Value Store and UserDefaults together
- [x] Dynamic storage type via variables

## Usage
### Basic Framework Usage
Basically, the usage is the same as the Observable macro in the Observation framework.
Use the Storage macro instead of the Observable macro. This change alone allows you to store properties permanently.

#### Model Definition
```swift
import SwiftStorage

@Storage
final class SwiftStorageModel {
    var storedValue: Bool

    init() {
        self.storedValue = false
    }
}
```

#### Use with SwiftUI
```swift
import SwiftUI

struct SwiftStorageView: View {
    @State private var swiftStorage = SwiftStorageModel()

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Bool", isOn: $swiftStorage.storedValue)
            }
        }
    }
}
```

### Property Macros
Each property in a `@Storage` class can be annotated with a macro to control its behavior. The following table summarizes the available macros:

| Macro | Persistence | Observation | Description |
|---|---|---|---|
| *(none)* | Yes | Yes | Default. Persisted and observed. |
| `@Attribute` | Yes | Yes | Customize storage key, type, and options. |
| `@Attribute(.ephemeral)` | No | Yes | Observation tracking only, not persisted. |
| `@ObservationTracked` | No | Yes | Standard Apple Observation macro. |
| `@Transient` | No | No | Neither persisted nor observed. |
| `@ObservationIgnored` | No | No | Standard Apple macro to ignore observation. |

#### Disable Persistence
If it is a constant, it will not be saved. Also, if the `@Transient` macro is applied, even if it is a variable, it will not be saved and it will not participate in observation tracking.

```swift
import SwiftStorage

@Storage
final class SwiftStorageModel {
    var storedValue: Bool

    @Transient
    var temporaryValue: String

    let constantValue: String

    init() {
        self.storedValue = false
        self.temporaryValue = ""
        self.constantValue = ""
    }
}
```

#### Observation-Only Properties
Use `@Attribute(.ephemeral)` or `@ObservationTracked` for properties that should trigger SwiftUI view updates but should **not** be persisted to storage. This is useful for transient UI state.

```swift
import SwiftStorage

@Storage
final class SwiftStorageModel {
    var persistedValue: Bool

    @Attribute(.ephemeral)
    var observedOnly: Bool

    @ObservationTracked
    var trackedOnly: Bool

    init() {
        self.persistedValue = false
        self.observedOnly = false
        self.trackedOnly = false
    }
}
```

Both `@Attribute(.ephemeral)` (provided by SwiftStorage, inspired by SwiftData's `Schema.Attribute.Option.ephemeral`) and `@ObservationTracked` (provided by Apple's Observation framework) are supported.

### Customize Keys
Use `@Attribute` to specify a custom storage key for a property.

```swift
import SwiftStorage

@Storage
final class SwiftStorageModel {
    @Attribute(key: "MyCustomKey")
    var customKeyValue: Bool

    init() {
        self.customKeyValue = false
    }
}
```

### Key Hashing
By default, all storage keys are hashed at compile time using [Hashify](https://github.com/KC-2001MS/Hashify). This means the original key names do not appear in the compiled binary, preventing them from being discovered through disassembly.

To disable hashing for a specific property (e.g., for debugging or interoperability), use `hashed: false`:

```swift
import SwiftStorage

@Storage
final class SwiftStorageModel {
    // Key is hashed (default, recommended)
    var secureValue: Bool

    // Key is hashed with a custom key
    @Attribute(key: "MyKey")
    var hashedCustomKey: Bool

    // Key is NOT hashed (plain text)
    @Attribute(key: "PlainKey", hashed: false)
    var debugValue: Bool

    init() {
        self.secureValue = false
        self.hashedCustomKey = false
        self.debugValue = false
    }
}
```

### iCloud Key Value Store
Use `@Storage(type: .cloud)` to store properties in iCloud Key Value Store (`NSUbiquitousKeyValueStore`). Changes sync automatically across devices.

```swift
import SwiftStorage

@Storage(type: .cloud)
final class CloudSettings {
    var syncedValue: Bool

    var syncedName: String

    init() {
        self.syncedValue = false
        self.syncedName = ""
    }
}
```

When another device changes a value, SwiftStorage automatically receives the `didChangeExternallyNotification` and triggers Observation updates. All SwiftUI views that reference the property will refresh automatically.

#### Mixing Local and Cloud Storage
You can override the class-level storage type on a per-property basis using `@Attribute(type:)`. This lets you keep some properties local while syncing others via iCloud.

```swift
import SwiftStorage

@Storage(type: .cloud)
final class CloudSettings {
    // Synced via iCloud (inherits class default)
    var cloudValue: Bool

    // Stored locally only (overrides class default)
    @Attribute(type: .local, key: "localOnly")
    var localValue: Bool

    init() {
        self.cloudValue = false
        self.localValue = false
    }
}
```

The type resolution order is:
1. `@Attribute(type:)` on the property (highest priority)
2. `@Storage(type:)` on the class
3. `.local` (default)

#### Custom UserDefaults Suite
Use `.localWith(suite:)` to store properties in a specific UserDefaults suite (e.g., for App Groups shared between app and extensions).

```swift
import SwiftStorage

@Storage(type: .localWith(suite: "group.com.example"))
final class SharedSettings {
    var sharedValue: Bool

    init() {
        self.sharedValue = false
    }
}
```

You can also override the suite per property:

```swift
@Storage
final class MixedSettings {
    var defaultValue: Bool

    @Attribute(type: .localWith(suite: "group.com.example"))
    var sharedValue: Bool

    init() {
        self.defaultValue = false
        self.sharedValue = false
    }
}
```

#### Dynamic Storage Type
`@Attribute(type:)` accepts variables in addition to literals. The storage backend is resolved at runtime via the `StorageBackend` protocol.

```swift
import SwiftStorage

let customType: StorageType = .localWith(suite: "group.com.example")

@Storage
final class DynamicSettings {
    @Attribute(type: customType)
    var dynamicValue: Bool

    init() {
        self.dynamicValue = false
    }
}
```

#### View Integration
No special property wrapper is needed. Use `@State`, `@Bindable`, and `@Binding` as usual:

```swift
struct ParentView: View {
    @State private var settings = CloudSettings()

    var body: some View {
        Toggle("Synced", isOn: $settings.cloudValue)
        ChildView(settings: settings)
    }
}

struct ChildView: View {
    @Bindable var settings: CloudSettings

    var body: some View {
        Toggle("Also Synced", isOn: $settings.cloudValue)
        // Updates from other devices are reflected here automatically
    }
}
```

> **Note:** Your app must have the iCloud Key-Value Store entitlement enabled for cloud storage to work.

## Installation
You can add it to your project using the Swift Package Manager To add SwiftStorage to your Xcode project, select File > Add Package Dependancies... and find the repository URL:  
`https://github.com/KC-2001MS/SwiftStorage.git`.

## Contributions
See [CONTRIBUTING.md](https://github.com/KC-2001MS/SwiftStorage/blob/main/CONTRIBUTING.md) if you want to make a contribution.

## Documents
Documentation on the SwiftStorage framework can be found [here](https://iroiro.dev/SwiftStorage/documentation/swiftstorage/).

## License
This library is released under Apache-2.0 license. See [LICENSE](https://github.com/KC-2001MS/SwiftStorage/blob/main/LICENSE) for details.

## Supporting
If you would like to make a donation to this project, please click here. The money you give will be used to improve my programming skills and maintain the application.  
<a href="https://www.buymeacoffee.com/iroiro" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" >
</a>  
[Pay by PayPal](https://paypal.me/iroiroWork?country.x=JP&locale.x=ja_JP)

## Author
[Keisuke Chinone](https://github.com/KC-2001MS)
