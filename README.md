# SwiftStorage
SwiftStorage is an easy way to persist data without Key Value. And it is designed to integrate seamlessly with SwiftUI.

## Features and Futures
I would like the framework to have the following features
- [x] Support for Observation framework
- [x] Can be disabled on a per-property basis
- [x] Save in UserDefaults
- [ ] Save in Key Value Store
- [x] Specify keys individually
- [ ] Key Value Store and UserDefaults together
Those not checked are to be realized in the future. However, we do not know when this will be, as our vision for implementation is not set in stone.
## Usage
### Basic Framework Usage
Basically, the usage is the same as the Observable macro in the Observation framework.
Use the Storage macro instead of the Observable macro. This change alone allows you to store properties permanently.
#### Model Definition
```swift
import Observation
import Foundation
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
### Disable persistence
If it is a constant, it will not be saved. Also, if the Transient macro is applied, even if it is a variable, it will not be saved.
```swift
import Observation
import Foundation
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
