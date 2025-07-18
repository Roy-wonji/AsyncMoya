//
//  Extension+Data.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation

/// `Data`를 지정된 `Decodable` 타입으로 디코딩하는 편의 메서드를 제공하는 확장입니다.
extension Data {
  /// JSON 형식의 바이트 시퀀스를 주어진 `Decodable` 타입으로 디코딩합니다.
  ///
  /// - Parameter type: 디코딩할 대상 `Decodable` 타입
  /// - Returns: 디코딩된 타입의 인스턴스
  /// - Throws: 디코딩 실패 시 `DecodingError` 또는 기타 오류를 던집니다.
  func decoded<T: Decodable>(as type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: self)
  }
}

