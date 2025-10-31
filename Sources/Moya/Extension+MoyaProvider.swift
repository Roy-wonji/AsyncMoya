//
//  Extension+MoyaProvider.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation
import Combine

import Moya
import CombineMoya

import RxMoya
import RxSwift

import LogMacro
import EventLimiter


extension MoyaProvider {
  // MARK: - Combine 퍼블리셔 기반 async/await 요청
  
  /// Combine 퍼블리셔 파이프라인을 async/await로 래핑한 네트워크 요청
  ///
  /// 이 메서드는 Combine의 `requestPublisher`를 사용하여 네트워크 요청을 수행하고,
  /// 결과를 지정된 타입으로 디코딩하여 반환합니다. 300ms 스로틀링을 적용하여
  /// 중복 요청을 방지합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let user = try await provider.requestWithCombine(.getUser(id: 1), decodeTo: User.self)
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable` 타입
  /// - Returns: 디코딩된 객체 `T`
  /// - Throws: 
  ///   - `DataError.noData`: HTTP 응답이 없는 경우
  ///   - `MoyaError.statusCode`: HTTP 400 상태 코드
  ///   - `DataError.customError`: HTTP 404 상태 코드와 함께 커스텀 에러 응답
  ///   - `DataError.unhandledStatusCode`: 처리되지 않은 HTTP 상태 코드
  ///   - 디코딩 오류, 네트워크 오류 등
  public func requestWithCombine<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
  ) async throws ->  T {
    return try await withCheckedThrowingContinuation { continuation in
      // async/await API의 일부로, 비동기 작업을 동기식으로 변환할 때 사용됩니다. 여기서 continuation은 비동기 작업이 완료되면 값을 반환하거나 오류를 던지기 위해 사용
      var cancellable: AnyCancellable?
      cancellable = self.requestPublisher(target)
        .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)  // 300 밀리 초 동안 하나의 요청 만 허용 하게 허용
        .tryMap { response -> Data in
          guard let httpResponse = response.response else {
            throw DataError.noData
          }
          switch httpResponse.statusCode {
          case 200, 201, 204, 401:
            return response.data
          case 400:
            throw MoyaError.statusCode(response)
          case 404:
            let errorResponse = try response.data.decoded(as: ResponseError.self)
            throw DataError.customError(errorResponse)
          default:
            throw DataError.unhandledStatusCode(httpResponse.statusCode)
          }
        }
        .tryCompactMap { data -> T? in
          if data.isEmpty {
            return nil
          }
          return try data.decoded(as: T.self)
        }
        .mapError { error -> MoyaError in
          if let moyaError = error as? MoyaError {
            Log.error("MoyaError occurred: \(moyaError.localizedDescription)")
            if case .statusCode(let response) = moyaError, response.statusCode == 400{
              #logError("400 토큰 인증실패: triggering retry logic")
              return moyaError
            }
            return moyaError
          } else if let decodingError = error as? DecodingError {
            #logError("DecodingError occurred: \(decodingError.localizedDescription)")
            return MoyaError.underlying(decodingError, nil)
          } else if let dataError = error as? DataError {
            #logError("DataError occurred: \(dataError.localizedDescription)")
            return MoyaError.underlying(dataError, nil)
          } else {
            let unknownError = NSError(domain: "Unknown Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."])
            Log.error("Unknown error occurred")
            return MoyaError.underlying(unknownError, nil)
          }
        }
        .sink(receiveCompletion: { completion in
          switch completion {
          case .finished:
            break
          case .failure(let error):
            continuation.resume(throwing: error)
            cancellable?.cancel()
            #logError("네트워크 에러", error)
          }
        }, receiveValue: {  decodedObject in
          continuation.resume(returning: decodedObject)
          #logNetwork("\(type) 데이터 통신", decodedObject)
        })
    }
  }

  // MARK: - HTTP 500 정상 처리 async/await 요청
  
  /// HTTP 500을 성공으로 간주하는 async/await 네트워크 요청
  ///
  /// 이 메서드는 HTTP 500 상태 코드를 정상 응답으로 처리하는 특별한 요청 메서드입니다.
  /// 일반적으로 서버 오류로 간주되는 500 상태 코드를 성공 케이스로 처리해야 하는
  /// 특수한 API 요구사항에 사용됩니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let result = try await provider.requestAllow500(.specialEndpoint, decodeTo: Response.self)
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable & Sendable` 타입
  /// - Returns: 디코딩된 객체 `T`
  /// - Throws:
  ///   - `DataError.noData`: HTTP 응답이 없는 경우
  ///   - `MoyaError.statusCode`: HTTP 400 상태 코드
  ///   - `DataError.customError`: HTTP 404 상태 코드와 함께 커스텀 에러 응답
  ///   - `DataError.unhandledStatusCode`: 509 및 기타 처리되지 않은 상태 코드
  public func requestAllow500<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
  ) async throws -> T {
    let throttle = Throttler(for: 0.3, latest: true)
    return try await withCheckedThrowingContinuation { continuation in
      throttle {
        self.request(target) { result in
          let finalResult: Result<T, Error>
          switch result {
          case .success(let response):
            guard let httpResponse = response.response else {
              finalResult = .failure(DataError.noData)
              break
            }
            // HTTP 상태 코드에 따른 처리
            switch httpResponse.statusCode {
            case 200, 201, 204, 401, 500:
              // 500도 정상 처리 상태로 간주
              if response.data.isEmpty, T.self == Void.self {
                finalResult = .success(Void() as! T)
              } else {
                let decodeResult: Result<T, Error> = Result {
                  try response.data.decoded(as: T.self)
                }.mapError { error in
                  #logError("DecodingError occurred: \(error.localizedDescription)")
                  return MoyaError.underlying(error, nil)
                }
                finalResult = decodeResult
              }
            case 400:
              finalResult = .failure(MoyaError.statusCode(response))
            case 404:
              let errorDecodeResult: Result<ResponseError, Error> = Result {
                try response.data.decoded(as: ResponseError.self)
              }.mapError { error in
                return MoyaError.underlying(error, nil)
              }
              switch errorDecodeResult {
              case .success(let errorResponse):
                finalResult = .failure(DataError.customError(errorResponse))
              case .failure(let error):
                finalResult = .failure(error)
              }
            case 509:
              // 509 상태 코드만 에러로 처리
              finalResult = .failure(DataError.unhandledStatusCode(httpResponse.statusCode))
            default:
              // 기타 상태 코드는 에러로 간주
              finalResult = .failure(DataError.unhandledStatusCode(httpResponse.statusCode))
            }
            
          case .failure(let error):
            finalResult = .failure(error)
          }
          // Result에 따라 continuation 종료
          switch finalResult {
          case .success(let value):
            continuation.resume(returning: value)
            #logNetwork("\(type) 데이터 통신", value)
          case .failure(let error):
            continuation.resume(throwing: error)
            #logError("네트워크 에러 발생: \(error.localizedDescription)")
          }
        }
      }
    }
  }

  // MARK: - 순수 async/await 요청
  
  /// Combine 없이 순수 async/await로 수행하는 네트워크 요청
  ///
  /// 이 메서드는 Combine 프레임워크에 의존하지 않고 순수한 async/await 패턴으로
  /// 네트워크 요청을 수행합니다. 300ms 스로틀링을 적용하여 중복 요청을 방지합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let user = try await provider.request(.getUser(id: 1), decodeTo: User.self)
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable & Sendable` 타입
  /// - Returns: 디코딩된 객체 `T`
  /// - Throws:
  ///   - `DataError.noData`: HTTP 응답이 없는 경우
  ///   - `MoyaError.statusCode`: HTTP 400 상태 코드
  ///   - `DataError.customError`: HTTP 404 상태 코드와 함께 커스텀 에러 응답
  ///   - `DataError.unhandledStatusCode`: 처리되지 않은 HTTP 상태 코드
  public func request<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
  ) async throws -> T {
    let throttle = Throttler(for: 0.3, latest: true)
    return try await withCheckedThrowingContinuation { continuation in
      throttle {
        // MoyaProvider를 사용해 비동기 요청 처리
        self.request(target) { result in
          let finalResult: Result<T, Error>
          switch result {
          case .success(let response):
            guard let httpResponse = response.response else {
              finalResult = .failure(DataError.noData)
              break
            }
            // HTTP 상태 코드에 따른 처리
            switch httpResponse.statusCode {
            case 200, 201, 204, 401:
              // 정상 상태 코드
              if response.data.isEmpty, T.self == Void.self {
                finalResult = .success(Void() as! T)
              } else {
                let decodeResult: Result<T, Error> = Result {
                  try response.data.decoded(as: T.self)
                }.mapError { error in
                  #logError("DecodingError occurred: \(error.localizedDescription)")
                  return MoyaError.underlying(error, nil)
                }
                finalResult = decodeResult
              }
            case 400:
              finalResult = .failure(MoyaError.statusCode(response))
            case 404:
              let errorDecodeResult: Result<ResponseError, Error> = Result {
                try response.data.decoded(as: ResponseError.self)
              }.mapError { error in
                return MoyaError.underlying(error, nil)
              }
              switch errorDecodeResult {
              case .success(let errorResponse):
                finalResult = .failure(DataError.customError(errorResponse))
              case .failure(let error):
                finalResult = .failure(error)
              }
            default:
              finalResult = .failure(DataError.unhandledStatusCode(httpResponse.statusCode))
            }
            
          case .failure(let error):
            finalResult = .failure(error)
          }
          // Result에 따라 continuation 종료
          
          switch finalResult {
          case .success(let value):
            continuation.resume(returning: value)
            #logNetwork("\(type) 데이터 통신", value)
          case .failure(let error):
            continuation.resume(throwing: error)
            #logError("네트워크 에러 발생: \(error.localizedDescription)")
          }
        }
      }
    }
  }

  // MARK: - AsyncThrowingStream 처리
  
  /// AsyncThrowingStream을 사용한 스트리밍 네트워크 요청
  ///
  /// 이 메서드는 `AsyncThrowingStream`을 반환하여 데이터를 스트리밍 방식으로 처리할 수 있게 합니다.
  /// 실시간 데이터나 연속적인 응답이 필요한 경우에 유용합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let stream = provider.requestThrowingStream(.getUpdates, decodeTo: Update.self)
  /// 
  /// do {
  ///     for try await update in stream {
  ///         print("Received update: \(update)")
  ///     }
  /// } catch {
  ///     print("Stream error: \(error)")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable & Sendable` 타입
  /// - Returns: 디코딩된 객체들을 방출하는 `AsyncThrowingStream<T, Error>`
  public func requestThrowingStream<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
  ) -> AsyncThrowingStream<T, Error> {
    // 퍼블리셔를 미리 준비합니다.
    let provider = MoyaProvider<Target>()
    let publisher = provider.requestPublisher(target)
      .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)  // 300 밀리 초 동안 하나의 요청 만 허용 하게 허용
      .tryMap { response -> Data in
        guard let httpResponse = response.response else {
          throw DataError.noData
        }
        switch httpResponse.statusCode {
        case 200, 201, 204, 401:
          return response.data
        case 400:
          throw DataError.badRequest
        case 404:
          let errorResponse = try response.data.decoded(as: ResponseError.self)
          throw DataError.customError(errorResponse)
        default:
          throw DataError.unhandledStatusCode(httpResponse.statusCode)
        }
      }
      .tryCompactMap { data -> T?  in
        if data.isEmpty {
          return nil
        }
        return try data.decoded(as: T.self)
      }
      .mapError { error in
        if let moyaError = error as? MoyaError {
          return DataError.moyaError(moyaError)
        } else if let decodingError = error as? DecodingError {
          return DataError.decodingError(decodingError)
        } else if let dataError = error as? DataError {
          return dataError
        } else {
          return DataError.unknownError
        }
      }
      .eraseToAnyPublisher()
    
    // AsyncThrowingStream을 생성하고 반환합니다.
    return AsyncThrowingStream { continuation in
      nonisolated(unsafe) var cancellable: AnyCancellable?
      
      cancellable = publisher.sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            continuation.finish()
          case .failure(let error):
            continuation.finish(throwing: error)
          }
        },
        receiveValue: { decodedObject in
          continuation.yield(decodedObject)
          Log.network("\(type) 데이터 통신", decodedObject)
        }
      )
      
      continuation.onTermination = { @Sendable (async) in
        cancellable?.cancel()
      }
    }
  }

  // MARK: - AsyncStream 처리
  
  /// AsyncStream을 사용한 Result 기반 스트리밍 네트워크 요청
  ///
  /// 이 메서드는 `AsyncStream<Result<T, Error>>`을 반환하여 성공과 실패를 모두 포함하는
  /// 스트리밍 데이터를 처리할 수 있게 합니다. 에러 처리가 중요한 스트리밍 시나리오에 적합합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let stream = provider.requestStream(.getUpdates, decodeTo: Update.self)
  /// 
  /// for await result in stream {
  ///     switch result {
  ///     case .success(let update):
  ///         print("Received update: \(update)")
  ///     case .failure(let error):
  ///         print("Error: \(error)")
  ///     }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable & Sendable` 타입
  /// - Returns: Result로 래핑된 디코딩된 객체들을 방출하는 `AsyncStream<Result<T, Error>>`
  public func requestStream<T: Decodable & Sendable>(
    _ target: Target,
    decodeTo type: T.Type
  ) -> AsyncStream<Result<T, Error>> {
    // 퍼블리셔를 미리 준비합니다.
    let provider = MoyaProvider<Target>()
    let publisher = provider.requestPublisher(target)
      .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)  // 300 밀리 초 동안 하나의 요청 만 허용 하게 허용
      .tryMap { response -> Data in
        guard let httpResponse = response.response else {
          throw DataError.noData
        }
        switch httpResponse.statusCode {
        case 200, 201, 204, 401:
          return response.data
        case 400:
          throw DataError.badRequest
        case 404:
          let errorResponse = try response.data.decoded(as: ResponseError.self)
          throw DataError.customError(errorResponse)
        default:
          throw DataError.unhandledStatusCode(httpResponse.statusCode)
        }
      }
      .tryCompactMap { data -> T?  in
        if data.isEmpty {
          return nil
        }
        return try data.decoded(as: T.self)
      }
      .mapError { error in
        if let moyaError = error as? MoyaError {
          return DataError.moyaError(moyaError)
        } else if let decodingError = error as? DecodingError {
          return DataError.decodingError(decodingError)
        } else if let dataError = error as? DataError {
          return dataError
        } else {
          return DataError.unknownError
        }
      }
    // AsyncStream을 생성하고 반환합니다.
    return AsyncStream { continuation in
      nonisolated(unsafe) var cancellable: AnyCancellable?
      
      cancellable = publisher.sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            continuation.finish()
          case .failure(let error):
            continuation.yield(.failure(error))
            continuation.finish()
          }
        },
        receiveValue: {  decodedObject in
          continuation.yield(.success(decodedObject))
          #logNetwork("\(type) 데이터 통신", decodedObject)
        }
      )
      
      continuation.onTermination = { @Sendable (async) in
        cancellable?.cancel()
      }
    }
  }

  // MARK: - RxSwift Single
  
  /// RxSwift Single을 사용한 네트워크 요청
  ///
  /// 이 메서드는 RxSwift의 `Single<T>` 타입을 반환하여 단일 값을 방출하는
  /// reactive 스트림을 제공합니다. 300ms 스로틀링을 적용하여 중복 요청을 방지합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let disposable = provider.requestRxSingle(.getUser(id: 1), decodeTo: User.self)
  ///     .subscribe(
  ///         onSuccess: { user in
  ///             print("User: \(user)")
  ///         },
  ///         onFailure: { error in
  ///             print("Error: \(error)")
  ///         }
  ///     )
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable` 타입
  /// - Returns: 디코딩된 객체를 방출하는 `Single<T>`
  public func requestRxSingle<T: Decodable>(
    _ target: Target,
    decodeTo type: T.Type
  ) -> Single<T> {
    return self.rx.request(target)
      .asObservable()
      .throttle(.milliseconds(300), scheduler: MainScheduler.instance) // throttle 적용: 300 밀리초 동안 하나의 요청만 허용
      .flatMap { response -> Observable<T> in
        do {
          let decodedObject = try response.data.decoded(as: T.self)
          return .just(decodedObject)
        } catch let decodingError {
          #logError("Decoding error: \(decodingError.localizedDescription)")
          return .error(decodingError)
        }
      }
      .catch { error in
        if let moyaError = error as? MoyaError {
          Log.error("MoyaError occurred: \(moyaError.localizedDescription)")
          if case .statusCode(let response) = moyaError, response.statusCode == 400 {
            #logError("400 토큰 인증실패: triggering retry logic")
          }
          return .error(moyaError)
        } else {
          let unknownError = NSError(
            domain: "Unknown Error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
          )
          #logError("Unknown error occurred")
          return .error(MoyaError.underlying(unknownError, nil))
        }
      }
      .do(onNext: { data in
        #logNetwork("\(type) 데이터 통신", data)
      }, onError: { error in
        #logError("네트워크 에러", error.localizedDescription)
      })
      .asSingle() // Observable을 다시 Single로 변환
  }

  // MARK: - RxSwift Observable
  
  /// RxSwift Observable을 사용한 네트워크 요청
  ///
  /// 이 메서드는 RxSwift의 `Observable<T>` 타입을 반환하여 여러 값을 방출할 수 있는
  /// reactive 스트림을 제공합니다. 300ms 스로틀링을 적용하여 중복 요청을 방지합니다.
  ///
  /// ```swift
  /// let provider = MoyaProvider<APIService>()
  /// let disposable = provider.requestRxObservable(.getUpdates, decodeTo: Update.self)
  ///     .subscribe(
  ///         onNext: { update in
  ///             print("Update: \(update)")
  ///         },
  ///         onError: { error in
  ///             print("Error: \(error)")
  ///         },
  ///         onCompleted: {
  ///             print("Completed")
  ///         }
  ///     )
  /// ```
  ///
  /// - Parameters:
  ///   - target: 호출할 Moya `Target` 엔드포인트
  ///   - type: 디코딩할 `Decodable` 타입
  /// - Returns: 디코딩된 객체들을 방출하는 `Observable<T>`
  public func requestRxObservable<T: Decodable>(
    _ target: Target,
    decodeTo type: T.Type
  ) -> Observable<T> {
    return self.rx.request(target)
      .observe(on: MainScheduler.instance)
      .asObservable()
      .throttle(.milliseconds(300), latest: true, scheduler: MainScheduler.asyncInstance)
      .flatMap { response -> Observable<T> in
        do {
          let decodedObject = try response.data.decoded(as: T.self)
          return .just(decodedObject)
        } catch let decodingError {
          #logError("디코딩 에러: \(decodingError.localizedDescription)")
          return .error(decodingError)
        }
      }
      .catch { error in
        // Handle errors from Moya
        if let moyaError = error as? MoyaError {
          #logError("MoyaError occurred: \(moyaError.localizedDescription)")
          if case .statusCode(let response) = moyaError, response.statusCode == 400 {
            #logError("400 토큰 인증실패: triggering retry logic")
          }
          return .error(moyaError)
        } else {
          let unknownError = NSError(
            domain: "Unknown Error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
          )
          Log.error("Unknown error occurred")
          return .error(MoyaError.underlying(unknownError, nil))
        }
      }
      .do(onNext: { data in
        #logNetwork("\(type) 데이터 통신", data)
      }, onError: { error in
        #logError("네트워크 에러", error.localizedDescription)
      })
  }
}
