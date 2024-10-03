# AsyncMoya

![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
[![License](https://img.shields.io/github/license/pelagornis/PLCommand)](https://github.com/pelagornis/PLCommand/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platforms-macOS%2010.5-red)


## Installation
PLCommand was deployed as Swift Package Manager. Package to install in a project. Add as a dependent item within the swift manifest.
```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/Roy-wonji/AsyncMoya.git", from: "1.0.0")
    ],
    ...
)
```
Then import the PLCommand from thr location you want to use.

```swift
import AsyncMoya
```


## License
**PLCommand** is under MIT license. See the [LICENSE](LICENSE) file for more info.


## Usage
####  requestAsync

```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

 func getDate() async throws -> CurrentDate? {
    return try await provider.requestAsync(.getDate, decodeTo: CurrentDate.self)
}
```

####  requestAsyncStream


```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

 func getDate() async throws -> CurrentDate? {
    for try await result in provider.requestAsyncStream(.getDate, decodeTo: CurrentDate.self) {
        if let currentDate = try? result.get() {
            return currentDate
        }
    }
    return nil
}
```


### requestAsyncThrowingStream


```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

func getDate() async throws -> CurrentDate? {
    for try await currentDate in provider.requestAsyncThrowingStream(.getDate, decodeTo: CurrentDate.self) {
        return currentDate
    }
    return nil
}
```

### requestRxSingle
```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

func getDate() async throws -> CurrentDate? {
    return try await withCheckedThrowingContinuation { continuation in
        let cancellable = provider.requestRxSingle(.getDate, decodeTo: CurrentDate.self)
            .asObservable()
            .subscribe(onNext: { decodedObject in
                continuation.resume(returning: decodedObject)
            }, onError: { error in
                continuation.resume(throwing: error)
            })
    }
}
```

### requestRxObservable

```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

func getDate() async throws -> CurrentDate? {
    return try await withCheckedThrowingContinuation { continuation in
        let cancellable = provider.requestRxObservable(.getDate, decodeTo: CurrentDate.self)
            .subscribe(onNext: { decodedObject in
                continuation.resume(returning: decodedObject)
                Log.network("Successfully retrieved CurrentDate: \(decodedObject)")
            }, onError: { error in
                continuation.resume(throwing: error)
                Log.error("Error retrieving CurrentDate: \(error.localizedDescription)")
            })
    }
}
```


### Log Use

```swift

use Error log
Log.error("Error retrieving CurrentDate: \(error.localizedDescription)")

use network log
Log.network("Successfully retrieved CurrentDate: \(decodedObject)")

use Debug log
Log.debug("디버그", "데이터")

```




