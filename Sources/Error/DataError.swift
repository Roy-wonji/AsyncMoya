//
//  DataError.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation
import Moya

/// 네트워크 요청 및 응답 처리 중 발생할 수 있는 다양한 오류를 표현하는 열거형
///
/// `DataError`는 AsyncMoya에서 네트워킹 과정에서 발생할 수 있는 모든 에러 케이스를 정의합니다.
/// HTTP 상태 코드 에러, 디코딩 에러, 서버 응답 에러 등을 체계적으로 분류하여 제공합니다.
///
/// ## 주요 에러 타입
///
/// ### 네트워크 관련 에러
/// - ``DataError/noData``: HTTP 응답 데이터가 없는 경우
/// - ``DataError/badRequest``: HTTP 400 Bad Request
/// - ``DataError/unhandledStatusCode(_:)``: 처리되지 않은 HTTP 상태 코드
///
/// ### 데이터 처리 에러
/// - ``DataError/decodingError(_:)``: JSON 디코딩 실패
/// - ``DataError/invalidatedType``: 타입 변환 실패
/// - ``DataError/emptyValue``: 예상되지 않은 빈 값
///
/// ### 서버 응답 에러
/// - ``DataError/customError(_:)``: 서버가 반환한 커스텀 에러 응답
/// - ``DataError/errorData(_:)``: 서버 에러 메시지 문자열
///
/// ## 사용 예시
///
/// ```swift
/// do {
///     let result = try await provider.requestAsync(.getUser, decodeTo: User.self)
/// } catch let error as DataError {
///     switch error {
///     case .noData:
///         print("응답 데이터가 없습니다")
///     case .decodingError(let decodingError):
///         print("디코딩 실패: \(decodingError)")
///     case .customError(let responseError):
///         print("서버 에러: \(responseError.detail)")
///     default:
///         print("기타 에러: \(error)")
///     }
/// }
/// ```
public enum DataError: Error {
  /// 일반 `Error` 객체를 래핑합니다.
  case error(Error)
  
  /// 예상치 못한 빈 값을 처리할 때 사용합니다.
  case emptyValue
  
  /// 타입 변환이 실패했을 때 사용합니다.
  case invalidatedType
  
  /// JSON 디코딩 중 발생한 오류를 래핑합니다.
  case decodingError(Error)
  
  /// HTTP 상태 코드가 허용되지 않을 때 사용합니다. (예: 400번대 제외)
  case statusCodeError(Int)
  
  /// 응답 본문에 데이터가 전혀 없을 때 사용합니다.
  case noData
  
  /// 잘못된 요청(HTTP 400)에 대한 오류를 나타냅니다.
  case badRequest
  
  /// 서버에서 반환한 커스텀 에러 응답을 래핑합니다.
  case customError(ResponseError)
  
  /// 미처리된(허용되지 않은) HTTP 상태 코드를 나타냅니다.
  case unhandledStatusCode(Int)
  
  /// 서버로부터 받은 오류 메시지 문자열을 직접 저장할 때 사용합니다.
  case errorData(String)
  
  /// `MoyaError` 객체를 래핑합니다.
  case moyaError(MoyaError)
  
  /// 그 외 알 수 없는 오류 상황을 처리할 때 사용합니다.
  case unknownError
}
