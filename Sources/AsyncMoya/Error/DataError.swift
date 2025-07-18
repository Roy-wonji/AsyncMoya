//
//  DataError.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation
import Moya

/// 네트워크 요청 및 응답 처리 중 발생할 수 있는 다양한 오류를 표현하는 열거형입니다.
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
