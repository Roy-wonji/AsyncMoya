# ``AsyncMoya``

Moya를 위한 현대적인 async/await, Combine, RxSwift 확장 라이브러리

## Overview

AsyncMoya는 Moya 네트워킹 라이브러리의 강력한 확장으로, Swift의 현대적인 동시성 기능과 reactive programming 패러다임을 지원합니다.

### 주요 기능

- **Async/Await 지원**: Swift 5.5+의 async/await 문법을 사용한 네트워킹
- **Combine 통합**: Combine 프레임워크와의 완벽한 통합
- **RxSwift 지원**: RxSwift Observable 및 Single 타입 지원
- **AsyncStream**: 스트리밍 데이터를 위한 AsyncStream 및 AsyncThrowingStream 지원
- **자동 스로틀링**: 중복 요청 방지를 위한 자동 throttling (300ms)
- **에러 핸들링**: 체계적인 HTTP 상태 코드 및 디코딩 에러 처리
- **로깅**: LogMacro를 통한 상세한 네트워킹 로그

## 시작하기

### Swift Package Manager로 설치

```swift
dependencies: [
    .package(url: "https://github.com/Roy-wonji/AsyncMoya.git", from: "1.0.0")
]
```

### 기본 사용법

```swift
import AsyncMoya
import Moya

// Moya Target 정의
enum APIService {
    case getUser(id: Int)
}

extension APIService: TargetType {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String {
        switch self {
        case .getUser(let id):
            return "/users/\(id)"
        }
    }
    // ... 기타 TargetType 구현
}

// AsyncMoya 사용
let provider = MoyaProvider<APIService>()

// Async/Await 방식
let user = try await provider.requestAsync(.getUser(id: 1), decodeTo: User.self)

// Combine 방식
let cancellable = provider.requestPublisher(.getUser(id: 1))
    .decode(type: User.self, decoder: JSONDecoder())
    .sink(receiveCompletion: { _ in }, receiveValue: { user in })

// RxSwift 방식
let disposable = provider.requestRxSingle(.getUser(id: 1), decodeTo: User.self)
    .subscribe(onSuccess: { user in }, onFailure: { error in })
```

## 주요 컴포넌트

### MoyaProvider Extensions

Moya의 `MoyaProvider`에 추가된 메서드들을 통해 다양한 방식으로 네트워킹을 수행할 수 있습니다:

#### Async/Await 메서드

- ``MoyaProvider/requestAsync(_:decodeTo:)`` - Combine 기반 async/await 요청
- ``MoyaProvider/requestAsyncAwait(_:decodeTo:)`` - 순수 async/await 요청  
- ``MoyaProvider/requestAsyncAwaitAllow500(_:decodeTo:)`` - HTTP 500을 정상으로 처리하는 요청

#### 스트리밍 메서드

- ``MoyaProvider/requestAsyncStream(_:decodeTo:)`` - AsyncStream 기반 Result 스트리밍
- ``MoyaProvider/requestAsyncThrowingStream(_:decodeTo:)`` - AsyncThrowingStream 기반 스트리밍

#### RxSwift 메서드

- ``MoyaProvider/requestRxSingle(_:decodeTo:)`` - RxSwift Single 요청
- ``MoyaProvider/requestRxObservable(_:decodeTo:)`` - RxSwift Observable 요청

### 에러 처리

``DataError``와 ``ResponseError`` 타입을 통해 체계적인 에러 처리를 제공합니다.

### 데이터 디코딩

Data 타입 확장을 통해 편리한 JSON 디코딩 기능을 제공합니다.

### 로깅

``MoyaLoggingPlugin``을 통해 상세한 네트워킹 로그를 확인할 수 있습니다.

## Topics

### MoyaProvider Extensions

- ``MoyaProvider/requestAsync(_:decodeTo:)``
- ``MoyaProvider/requestAsyncAwait(_:decodeTo:)``
- ``MoyaProvider/requestAsyncAwaitAllow500(_:decodeTo:)``
- ``MoyaProvider/requestAsyncStream(_:decodeTo:)``
- ``MoyaProvider/requestAsyncThrowingStream(_:decodeTo:)``
- ``MoyaProvider/requestRxSingle(_:decodeTo:)``
- ``MoyaProvider/requestRxObservable(_:decodeTo:)``

### Error Handling

- ``DataError``
- ``ResponseError``

### Logging

- ``MoyaLoggingPlugin``