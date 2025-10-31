# AsyncMoya Swift DocC 문서 가이드

이 가이드는 AsyncMoya 프로젝트에서 Swift DocC를 사용하여 문서를 생성하고 활용하는 방법을 설명합니다.

## 목차

1. [Swift DocC란?](#swift-docc란)
2. [프로젝트 설정](#프로젝트-설정)
3. [문서 빌드 방법](#문서-빌드-방법)
4. [문서 보기 및 탐색](#문서-보기-및-탐색)
5. [문서 호스팅](#문서-호스팅)
6. [문서 작성 가이드라인](#문서-작성-가이드라인)
7. [고급 기능](#고급-기능)
8. [트러블슈팅](#트러블슈팅)

## Swift DocC란?

Swift DocC는 Apple에서 개발한 공식 문서 생성 도구입니다. Swift 패키지의 소스 코드에서 API 문서를 자동으로 생성하고, 마크다운 기반의 추가 문서와 튜토리얼을 통합하여 풍부한 문서 사이트를 만들 수 있습니다.

### 주요 특징

- **자동 API 문서 생성**: 소스 코드의 주석에서 API 문서 자동 추출
- **인터랙티브 문서**: 검색, 필터링, 네비게이션 기능 내장
- **코드 예제 통합**: 실행 가능한 코드 예제 포함
- **크로스 플랫폼**: macOS, iOS, watchOS, tvOS 지원
- **웹 호스팅**: 정적 웹사이트로 배포 가능

## 프로젝트 설정

AsyncMoya 프로젝트는 이미 DocC가 설정되어 있습니다.

### Package.swift 설정 확인

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin.git", exact: "1.4.4"),
]
```

### Documentation Catalog 구조

```
Sources/
├── AsyncMoya/
│   └── AsyncMoya.docc/
│       └── AsyncMoya.md          # 메인 문서 페이지
├── Moya/
│   └── Extension+MoyaProvider.swift  # 주요 API 문서화
├── Error/
│   ├── DataError.swift           # 에러 타입 문서화
│   └── ResponseError.swift
├── Data/
│   └── Extension+Data.swift      # 유틸리티 문서화
└── MoyaLogging/
    └── MoyaLoggingPlugin.swift   # 플러그인 문서화
```

## 문서 빌드 방법

### 1. 기본 문서 빌드

```bash
# 프로젝트 루트 디렉토리에서 실행
swift package generate-documentation
```

### 2. 특정 타겟 문서 빌드

```bash
swift package generate-documentation --target AsyncMoya
```

### 3. 문서 미리보기 서버 실행

```bash
# 로컬 서버에서 문서 미리보기 (기본 포트: 8000)
swift package --disable-sandbox preview-documentation --target AsyncMoya
```

브라우저에서 `http://localhost:8000/documentation/asyncmoya` 접속

### 4. 커스텀 포트로 미리보기

```bash
swift package --disable-sandbox preview-documentation --target AsyncMoya --port 3000
```

### 5. 정적 HTML 파일 생성

```bash
# docs 디렉토리에 정적 파일 생성
swift package generate-documentation --target AsyncMoya --output-path ./docs
```

## 문서 보기 및 탐색

### 브라우저에서 문서 탐색

1. **메인 페이지**: 라이브러리 개요 및 시작 가이드
2. **API Reference**: 모든 public 타입과 메서드
3. **검색 기능**: 상단 검색 바에서 API 검색
4. **필터링**: 타입별 (클래스, 구조체, 열거형, 프로토콜) 필터링
5. **네비게이션**: 사이드바를 통한 계층적 탐색

### 주요 섹션

- **Getting Started**: 설치 및 기본 사용법
- **MoyaProvider Extensions**: async/await, Combine, RxSwift 메서드들
- **Error Handling**: DataError, ResponseError 타입들
- **Utilities**: Data 확장, 로깅 플러그인

## 문서 호스팅

### GitHub Pages로 호스팅

1. **문서 빌드 및 커밋**

```bash
# 정적 파일 생성
swift package generate-documentation --target AsyncMoya --output-path ./docs

# Git에 추가
git add docs/
git commit -m "📚 Update documentation"
git push origin main
```

2. **GitHub Pages 설정**
   - GitHub 저장소 → Settings → Pages
   - Source: Deploy from a branch
   - Branch: main
   - Folder: /docs

### GitHub Actions 자동화

`.github/workflows/docs.yml` 파일 생성:

```yaml
name: Build and Deploy Documentation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: "5.9"
    
    - name: Build Documentation
      run: |
        swift package generate-documentation --target AsyncMoya --output-path ./docs
    
    - name: Deploy to GitHub Pages
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./docs
```

## 문서 작성 가이드라인

### 1. API 문서화 주석 스타일

```swift
/// 메서드의 간단한 설명
///
/// 상세한 설명이 필요한 경우 여기에 작성합니다.
/// 여러 줄로 작성할 수 있습니다.
///
/// ```swift
/// // 사용 예제
/// let result = try await provider.request(.getUser, decodeTo: User.self)
/// ```
///
/// - Parameters:
///   - target: 호출할 API 엔드포인트
///   - type: 디코딩할 타입
/// - Returns: 디코딩된 객체
/// - Throws: 네트워크 오류 또는 디코딩 오류
public func request<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
) async throws -> T {
    // 구현
}
```

### 2. 타입 문서화

```swift
/// 에러 타입에 대한 설명
///
/// ## 주요 에러 케이스
///
/// ### 네트워크 관련
/// - ``DataError/noData``: 응답 데이터 없음
/// - ``DataError/badRequest``: HTTP 400 에러
///
/// ### 데이터 처리
/// - ``DataError/decodingError(_:)``: JSON 디코딩 실패
///
/// ## 사용 예시
///
/// ```swift
/// do {
///     let result = try await request()
/// } catch let error as DataError {
///     switch error {
///     case .noData:
///         print("데이터 없음")
///     default:
///         print("기타 에러")
///     }
/// }
/// ```
public enum DataError: Error {
    // ...
}
```

### 3. 마크다운 문서 (.docc 폴더 내)

```markdown
# ``AsyncMoya``

라이브러리에 대한 전체적인 설명

## Overview

AsyncMoya는 Moya의 현대적인 확장입니다...

## Topics

### Essential Classes

- ``MoyaProvider``

### Error Types

- ``DataError``
- ``ResponseError``

### Utilities

- ``Foundation/Data``
```

## 고급 기능

### 1. 코드 스니펫 검증

DocC는 문서의 코드 예제가 실제로 컴파일되는지 확인할 수 있습니다:

```swift
/// ```swift
/// // 이 코드는 실제로 컴파일되어 검증됩니다
/// let provider = MoyaProvider<APIService>()
/// let user = try await provider.request(.getUser(id: 1), decodeTo: User.self)
/// ```
```

### 2. 상호 참조 링크

```swift
/// 이 메서드는 ``DataError``를 던질 수 있습니다.
/// 자세한 정보는 ``MoyaProvider/request(_:decodeTo:)``를 참조하세요.
```

### 3. 플랫폼별 문서

```swift
/// iOS 15.0+에서만 사용 가능한 기능입니다.
///
/// > Important: 이 API는 iOS 15.0 이상에서만 지원됩니다.
@available(iOS 15.0, *)
public func newFeature() {
    // 구현
}
```

### 4. 경고 및 노트

```swift
/// > Warning: 이 메서드는 메인 스레드에서 호출해야 합니다.
///
/// > Note: 300ms 스로틀링이 자동으로 적용됩니다.
///
/// > Tip: 에러 처리를 위해 do-catch 블록을 사용하세요.
```

## 트러블슈팅

### 문제 1: "No documentation found" 오류

**원인**: Documentation Catalog이 올바르게 설정되지 않음

**해결책**:
```bash
# 올바른 폴더 구조 확인
ls Sources/AsyncMoya/AsyncMoya.docc/

# AsyncMoya.md 파일이 존재하는지 확인
cat Sources/AsyncMoya/AsyncMoya.docc/AsyncMoya.md
```

### 문제 2: 빌드 실패

**원인**: Swift 버전 호환성 문제

**해결책**:
```bash
# Swift 버전 확인
swift --version

# Package.swift에서 최소 Swift 버전 확인
cat Package.swift | grep swift-tools-version
```

### 문제 3: 미리보기 서버 접속 불가

**원인**: 방화벽 또는 포트 충돌

**해결책**:
```bash
# 다른 포트 사용
swift package --disable-sandbox preview-documentation --target AsyncMoya --port 8080

# 프로세스 확인
lsof -ti:8000
```

### 문제 4: 문서에 API가 표시되지 않음

**원인**: public 접근자가 없거나 문서화 주석이 없음

**해결책**:
```swift
// public 키워드 확인
public func myMethod() { }

// 문서화 주석 추가
/// 이 메서드에 대한 설명
public func myMethod() { }
```

## 명령어 요약

```bash
# 기본 문서 빌드
swift package generate-documentation

# 미리보기 서버 실행
swift package --disable-sandbox preview-documentation --target AsyncMoya

# 정적 파일 생성
swift package generate-documentation --target AsyncMoya --output-path ./docs

# 특정 포트에서 미리보기
swift package --disable-sandbox preview-documentation --target AsyncMoya --port 3000

# 도움말
swift package generate-documentation --help
```

## 참고 자료

- [Swift DocC 공식 문서](https://developer.apple.com/documentation/docc)
- [Swift Package Manager 가이드](https://swift.org/package-manager/)
- [DocC 플러그인 GitHub](https://github.com/apple/swift-docc-plugin)
- [마크다운 문법 가이드](https://www.markdownguide.org/)

---

이 가이드를 통해 AsyncMoya의 문서를 효과적으로 생성하고 관리할 수 있습니다. 문서는 지속적으로 업데이트하여 최신 상태를 유지하는 것이 중요합니다.
