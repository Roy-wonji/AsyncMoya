//
//  MoyaProvider+AsyncAwait.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/3/24.
//

import Foundation

import Moya

import LogMacro

extension MoyaProvider {
  /// Combine 없이 순수 async/await로 수행하는 네트워크 요청
  ///
  /// `mapResponse`를 사용하여 HTTP 상태 코드에 따라 성공/에러를 분기하고, `Decodable` 타입으로 디코딩합니다.
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: 디코딩된 객체 `T`
  public func request<T: Decodable & Sendable>(
    _ target: Target
  ) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
      self.request(target) { result in
        let finalResult: Result<T, Error> = ResponseMapper.map(result)
        switch finalResult {
        case .success(let value):
          continuation.resume(returning: value)
          #logNetwork("\(T.self) 데이터 통신", value)
        case .failure(let error):
          continuation.resume(throwing: error)
          #logError("네트워크 에러 발생: \(error.localizedDescription)")
        }
      }
    }
  }
}
