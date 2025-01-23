//
//  ResponseError.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation

public struct ResponseError: Decodable, Sendable {
  let detail: String
  let code: String
  
  public init(detail: String, code: String) {
    self.detail = detail
    self.code = code
  }
}

