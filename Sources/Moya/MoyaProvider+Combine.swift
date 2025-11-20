//
//  MoyaProvider+Combine.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/3/24.
//

import Foundation
import Combine

import Moya
import CombineMoya

import LogMacro

extension MoyaProvider {
  /// Combine 퍼블리셔 파이프라인을 async/await로 래핑한 네트워크 요청
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: 디코딩된 객체 `T`
  public func requestWithCombine<T: Decodable & Sendable>(
    _ target: Target
  ) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
      var cancellable: AnyCancellable?
      
      cancellable = self.requestPublisher(target)
        .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
        .map { (response: Response) -> Result<T, Error> in
          ResponseMapper.map(.success(response))
        }
        .catch { (error: MoyaError) -> Just<Result<T, Error>> in
          Just(ResponseMapper.map(.failure(error)))
        }
        .sink { result in
          switch result {
          case .success(let decoded):
            continuation.resume(returning: decoded)
            #logNetwork("\(T.self) 데이터 통신", decoded)
          case .failure(let error):
            continuation.resume(throwing: error)
            #logError("네트워크 에러", error)
          }
          cancellable?.cancel()
        }
    }
  }
  
  /// AsyncThrowingStream을 사용한 스트리밍 네트워크 요청
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: 디코딩된 객체들을 방출하는 `AsyncThrowingStream<T, Error>`
  public func requestThrowingStream<T: Decodable & Sendable>(
    _ target: Target
  ) -> AsyncThrowingStream<T, Error> {
    let publisher = self.requestPublisher(target)
      .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
      .map { (response: Response) -> Result<T, Error> in
        ResponseMapper.map(.success(response))
      }
      .catch { (error: MoyaError) -> Just<Result<T, Error>> in
        Just(ResponseMapper.map(.failure(error)))
      }
      .eraseToAnyPublisher()
    
    return AsyncThrowingStream { continuation in
      nonisolated(unsafe) var cancellable: AnyCancellable?
      
      cancellable = publisher.sink(
        receiveCompletion: { completion in
          if case .failure(let error) = completion {
            continuation.finish(throwing: error)
          } else {
            continuation.finish()
          }
        },
        receiveValue: { result in
          switch result {
          case .success(let value):
            continuation.yield(value)
            #logNetwork("\(T.self) 데이터 통신", value)
          case .failure(let error):
            continuation.finish(throwing: error)
          }
        }
      )
      
      continuation.onTermination = { @Sendable _ in
        cancellable?.cancel()
      }
    }
  }
  
  /// AsyncStream을 사용한 Result 기반 스트리밍 네트워크 요청
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: Result로 래핑된 디코딩된 객체들을 방출하는 `AsyncStream<Result<T, Error>>`
  public func requestStream<T: Decodable & Sendable>(
    _ target: Target
  ) -> AsyncStream<Result<T, Error>> {
    let publisher = self.requestPublisher(target)
      .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
      .map { (response: Response) -> Result<T, Error> in
        ResponseMapper.map(.success(response))
      }
      .catch { (error: MoyaError) -> Just<Result<T, Error>> in
        Just(ResponseMapper.map(.failure(error)))
      }
    
    return AsyncStream { continuation in
      nonisolated(unsafe) var cancellable: AnyCancellable?
      
      cancellable = publisher.sink(
        receiveCompletion: { completion in
          if case .failure(let error) = completion {
            continuation.yield(.failure(error))
          }
          continuation.finish()
        },
        receiveValue: { result in
          continuation.yield(result)
          if case .success(let value) = result {
            #logNetwork("\(T.self) 데이터 통신", value)
          }
        }
      )
      
      continuation.onTermination = { @Sendable _ in
        cancellable?.cancel()
      }
    }
  }
}
