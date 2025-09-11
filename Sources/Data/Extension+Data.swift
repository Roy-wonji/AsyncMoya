//
//  Extension+Data.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation

/// Data 타입에 JSON 디코딩 기능을 추가하는 확장
///
/// 이 확장은 `Data` 객체를 지정된 `Decodable` 타입으로 간편하게 디코딩할 수 있는
/// 유틸리티 메서드를 제공합니다. AsyncMoya의 모든 네트워킹 메서드에서 내부적으로 사용됩니다.
extension Data {
  /// JSON 데이터를 지정된 Decodable 타입으로 디코딩
  ///
  /// 이 메서드는 `JSONDecoder`를 사용하여 JSON 형식의 `Data`를 Swift 객체로 변환합니다.
  /// AsyncMoya의 모든 네트워킹 메서드에서 응답 데이터를 파싱할 때 사용됩니다.
  ///
  /// ```swift
  /// let jsonData = """
  /// {
  ///     "id": 1,
  ///     "name": "John Doe",
  ///     "email": "john@example.com"
  /// }
  /// """.data(using: .utf8)!
  /// 
  /// struct User: Decodable {
  ///     let id: Int
  ///     let name: String
  ///     let email: String
  /// }
  /// 
  /// let user = try jsonData.decoded(as: User.self)
  /// print(user.name) // "John Doe"
  /// ```
  ///
  /// - Parameter type: 디코딩할 대상 `Decodable` 타입
  /// - Returns: 디코딩된 타입의 인스턴스
  /// - Throws: 
  ///   - `DecodingError`: JSON 구조가 타입과 맞지 않거나 필수 키가 누락된 경우
  ///   - 기타 디코딩 관련 오류
  func decoded<T: Decodable>(as type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: self)
  }
}

