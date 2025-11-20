# AsyncMoya

![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
[![License](https://img.shields.io/github/license/pelagornis/PLCommand)](https://github.com/pelagornis/PLCommand/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platforms-iOS%2015.0%2B%20%7C%20macOS%2012.0%2B-blue)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://roy-wonji.github.io/AsyncMoya/documentation/asyncmoya/)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FMonsteel%2FAsyncMoya&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

**Moya를 위한 현대적인 async/await, Combine, RxSwift 확장 라이브러리**

💁🏻‍♂️ **iOS 15.0+, macOS 12.0+** 를 지원합니다<br>
💁🏻‍♂️ **Moya**를 기반으로 하여 구현되었습니다<br>
💁🏻‍♂️ **Swift Concurrency**, **Combine**, **RxSwift**를 모두 지원합니다<br>
💁🏻‍♂️ **자동 스로틀링**(300ms)으로 중복 요청을 방지합니다<br>
💁🏻‍♂️ **체계적인 에러 처리**와 **상세한 로깅**을 제공합니다

## ✨ 주요 특징

- 🚀 **Modern Concurrency**: Swift의 async/await 패턴 완벽 지원
- 🔄 **Reactive Programming**: Combine과 RxSwift 통합
- 📺 **Streaming Support**: AsyncStream과 AsyncThrowingStream 지원
- ⚡ **Auto Throttling**: 300ms 자동 스로틀링으로 중복 요청 방지
- 🛡️ **Error Handling**: 체계적인 HTTP 상태 코드 및 디코딩 에러 처리
- 📊 **Advanced Logging**: 상세한 네트워크 요청/응답 로깅
- 📖 **Complete Documentation**: Swift DocC로 작성된 완전한 API 문서

## 📚 문서

- **[📖 API 문서](https://roy-wonji.github.io/AsyncMoya/documentation/asyncmoya/)** - Swift DocC로 생성된 완전한 API 레퍼런스
- **[🔧 DocC 사용 가이드](DOCC_GUIDE.md)** - 문서 빌드 및 활용 방법

## 🏗️ 기반 기술

이 프로젝트는 [Moya](https://github.com/Moya/Moya)를 기반으로 구현되었습니다.<br>
보다 자세한 내용은 해당 라이브러리의 문서를 참고해 주세요


## 📦 설치

### Swift Package Manager

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/Roy-wonji/AsyncMoya.git", from: "1.0.6")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["AsyncMoya"]
        )
    ]
)
```

### Xcode에서 설치

1. Xcode에서 프로젝트를 열고
2. **File** → **Add Package Dependencies** 선택
3. 다음 URL을 입력: `https://github.com/Roy-wonji/AsyncMoya.git`
4. **Add Package** 클릭

### 사용하기

```swift
import AsyncMoya
```

## 🚀 빠른 시작

### 기본 설정

```swift
import AsyncMoya

// API 엔드포인트 정의
enum GitHubAPI {
    case user(String)
    case repos(String)
}

extension GitHubAPI: TargetType {
    var baseURL: URL { URL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .user(let username): return "/users/\(username)"
        case .repos(let username): return "/users/\(username)/repos"
        }
    }
    // ... 기타 TargetType 구현
}

// Provider 생성 (로깅 플러그인 포함)
let provider = MoyaProvider<GitHubAPI>(plugins: [MoyaLoggingPlugin()])
```

## 📋 사용 방법

### 🔥 Async/Await (추천)

#### 1. requestWithCombine - Combine + async/await 래핑

```swift
func getUser() async throws -> User {
    return try await provider.requestWithCombine(.user("octocat"))
}
```

#### 2. request - 순수 async/await

```swift
func getUser() async throws -> User {
    return try await provider.request(.user("octocat"))
}
```

### 📺 Streaming

#### AsyncThrowingStream

```swift
func getUpdates() async throws {
    let stream = provider.requestThrowingStream(.updates)
    
    do {
        for try await update in stream {
            print("새 업데이트: \(update)")
        }
    } catch {
        print("스트림 에러: \(error)")
    }
}
```

#### AsyncStream (Result 기반)

```swift
func getUpdatesWithErrorHandling() async {
    let stream = provider.requestStream(.updates)
    
    for await result in stream {
        switch result {
        case .success(let update):
            print("성공: \(update)")
        case .failure(let error):
            print("에러: \(error)")
        }
    }
}
```

### 🔄 Reactive Programming

#### RxSwift Single

```swift
import RxSwift

func getUser() -> Single<User> {
    return provider.requestRxSingle(.user("octocat"))
}

// 사용 예시
let disposable = getUser()
    .subscribe(
        onSuccess: { user in print("사용자: \(user)") },
        onFailure: { error in print("에러: \(error)") }
    )
```

#### RxSwift Observable

```swift
func getRepos() -> Observable<[Repository]> {
    return provider.requestRxObservable(.repos("octocat"))
}

// 사용 예시
let disposable = getRepos()
    .subscribe(
        onNext: { repos in print("저장소들: \(repos)") },
        onError: { error in print("에러: \(error)") }
    )
```

## 🛡️ 에러 처리

```swift
do {
    let user = try await provider.request(.user("octocat"))
    print("사용자: \(user)")
} catch let error as DataError {
    switch error {
    case .noData:
        print("응답 데이터가 없습니다")
    case .decodingError(let decodingError):
        print("디코딩 실패: \(decodingError)")
    case .customError(let responseError):
        print("서버 에러: \(responseError.detail)")
    case .unhandledStatusCode(let code):
        print("처리되지 않은 상태 코드: \(code)")
    default:
        print("기타 에러: \(error)")
    }
} catch {
    print("예상치 못한 에러: \(error)")
}
```


## 📊 고급 기능

### 로깅

AsyncMoya는 `MoyaLoggingPlugin`을 통해 상세한 네트워크 로깅을 제공합니다.

```swift
let provider = MoyaProvider<APIService>(plugins: [MoyaLoggingPlugin()])
```

로그 출력 예시:
```
⎡---------------------서버통신을 시작합니다.----------------------⎤
[GET] https://api.github.com/users/octocat
API: GitHubAPI.user("octocat")
헤더:
 ["Content-Type": "application/json"]
⎣------------------ Request END  -------------------------⎦

⎡------------------서버에게 Response가 도착했습니다. ------------------⎤
API: GitHubAPI.user("octocat")
상태 코드: [200]
URL: https://api.github.com/users/octocat
데이터:
  {"login": "octocat", "id": 1, "name": "The Octocat"}
⎣------------------ END HTTP (58-byte body) ------------------⎦
```

로그 관련 상세 사용법은 [LogMacro](https://github.com/Roy-wonji/LogMacro) 문서를 참고해주세요.

### 자동 스로틀링

모든 요청 메서드는 300ms 자동 스로틀링을 적용하여 중복 요청을 방지합니다.

## 🏗️ 문서 빌드

로컬에서 문서를 빌드하고 미리보기할 수 있습니다:

```bash
# 문서 빌드
swift package generate-documentation --target AsyncMoya

# 미리보기 서버 실행
swift package --disable-sandbox preview-documentation --target AsyncMoya
```

자세한 내용은 [DocC 사용 가이드](DOCC_GUIDE.md)를 참조하세요.

## 🤝 기여하기

개선의 여지가 있는 모든 것들에 대해 열려있습니다.
Pull Request를 통해 기여해주세요! 🙏

### 개발 환경 설정

1. 저장소 클론
2. Xcode에서 `Package.swift` 열기
3. 테스트 실행: `Cmd+U`
4. 문서 미리보기: `swift package --disable-sandbox preview-documentation --target AsyncMoya`

## 👨‍💻 저자

**서원지 (Roy)**
- 이메일: [suhwj81@gmail.com](mailto:suhwj81@gmail.com)
- GitHub: [@Roy-wonji](https://github.com/Roy-wonji)

## 📄 라이선스

AsyncMoya는 MIT 라이선스로 이용할 수 있습니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조해 주세요.

---

**Made with ❤️ by Roy**
