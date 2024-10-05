# AsyncMoya

![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
[![License](https://img.shields.io/github/license/pelagornis/PLCommand)](https://github.com/pelagornis/PLCommand/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platforms-macOS%2010.5-red)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FMonsteel%2FAsyncMoya&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

💁🏻‍♂️ iOS15+ 를 지원합니다.<br>
💁🏻‍♂️ Moya을 기반으로 하여 구현되었습니다.<br>
💁🏻‍♂️ Moya의 다양한 옵션(requestPublisher request, Moya의 기본 매소드)을 지원합니다.<br>

## 장점
✅ AsyncMoya을 사용하면, 네트워킹 코드를 좀더 간결하게 사용 할수 있어요!

## 기반
이 프로젝트는 [Moya](https://github.com/Moya/Moya)을 기반으로 구현되었습니다.<br>
보다 자세한 내용은 해당 라이브러리의 문서를 참고해 주세요


## Swift Package Manager(SPM) 을 통해 사용할 수 있어요
```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/Roy-wonji/AsyncMoya.git", from: "1.0.6")
    ],
    ...
)
```

```swift
import AsyncMoya
```

## 사용 방법</br>
### requestAsync
#### 컴바인이랑  async/await 을 같이 사용

```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

 func getDate() async throws -> CurrentDate? {
    return try await provider.requestAsync(.getDate, decodeTo: CurrentDate.self)
}
```

###  requestAsyncAwait
#### async/await만 사용하게 구현

```swift
import AsyncMoya

let provider = MoyaProvider<GitHub>(plugins: [MoyaLoggingPlugin()])

 func getDate() async throws -> CurrentDate? {
    return try await provider.requestAsyncAwait(.getDate, decodeTo: CurrentDate.self)
}
```


###  requestAsyncStream

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
로그 관련 사용은 [LogMacro](https://github.com/Roy-wonji/LogMacro) 해당 라이브러리에 문서를 참고 해주세요. <br>


## Auther
서원지(Roy) [suhwj81@gmail.com](suhwj81@gmail.com)


## 함께 만들어 나가요

개선의 여지가 있는 모든 것들에 대해 열려있습니다.<br>
PullRequest를 통해 기여해주세요. 🙏

## License

AsyncMoya 는 MIT 라이선스로 이용할 수 있습니다. 자세한 내용은 [라이선스](LICENSE) 파일을 참조해 주세요.<br>
AsyncMoya is available under the MIT license. See the  [LICENSE](LICENSE) file for more info.

