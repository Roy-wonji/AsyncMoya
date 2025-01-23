//
//  DataError.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation
import Moya

public enum DataError: Error {
  case error(Error)
  case emptyValue
  case invalidatedType
  case decodingError(Error)
  case statusCodeError(Int)
  case noData
  case badRequest
  case customError(ResponseError)
  case unhandledStatusCode(Int)
  case errorData(String)
  case moyaError(MoyaError)
  case unknownError
}
