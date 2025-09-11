//
//  ResponseError.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation

/// 서버로부터 반환된 에러 응답을 표현하는 모델입니다.
///
/// 이 구조체는 API 호출 실패 시 응답 본문에 포함된 에러 상세 메시지와 에러 코드를 디코딩하여 보관합니다.
public struct ResponseError: Decodable, Sendable {
  /// 에러에 대한 상세 설명 메시지
  public let detail: String

  /// 서버에서 정의한 에러 코드
  public let code: String

  /// 지정된 `detail`과 `code`로 `ResponseError`를 생성합니다.
  ///
  /// - Parameters:
  ///   - detail: 에러 설명 메시지
  ///   - code: 서버 정의 에러 코드
  public init(detail: String, code: String) {
    self.detail = detail
    self.code = code
  }
}

