//
//  ResponseMapper.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/3/24.
//

import Foundation
import Moya

import LogMacro

/// 공통 응답 매핑 유틸리티
enum ResponseMapper {
  static func map<T: Decodable>(
    _ result: Result<Response, MoyaError>
  ) -> Result<T, Error> {
    switch result {
    case .success(let response):
      guard let httpResponse = response.response else {
        return .failure(DataError.noData)
      }
      let statusCode = httpResponse.statusCode
      
      switch statusCode {
      case 200..<400:
        if response.data.isEmpty {
          guard T.self == Void.self, let voidValue = () as? T else {
            return .failure(DataError.emptyValue)
          }
          return .success(voidValue)
        }
        
        do {
          let decoded = try response.data.decoded(as: T.self)
          return .success(decoded)
        } catch {
          #logError("DecodingError occurred: \(error.localizedDescription)")
          return .failure(DataError.decodingError(error))
        }
        
      case 400..<500:
        if let errorResponse = try? response.data.decoded(as: ResponseError.self) {
          return .failure(DataError.customError(errorResponse))
        }
        return .failure(DataError.statusCodeError(statusCode))
        
      case 500..<600:
        return .failure(DataError.statusCodeError(statusCode))
        
      default:
        return .failure(DataError.unhandledStatusCode(statusCode))
      }
      
    case .failure(let moyaError):
      #logError("네트워크 에러 발생: \(moyaError.localizedDescription)")
      return .failure(moyaError)
    }
  }
}
