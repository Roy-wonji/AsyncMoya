//
//  BaseTargetType.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/10/24.
//

import Foundation
import Moya

/// `DataError`를 네트워크 에러 모델로 재사용합니다.
public typealias NetworkError = DataError

public protocol DomainType {
  var url: String { get }
  var baseURLString: String { get }
}

public protocol BaseTargetType: TargetType {
  associatedtype Domain: DomainType
  var domain: Domain { get }
  var urlPath: String { get }
  var error: [Int: NetworkError]? { get }
  var parameters: [String: Any]? { get }
}

public extension BaseTargetType {
  var baseURL: URL {
    guard let url = URL(string: domain.baseURLString) else {
      preconditionFailure("Invalid baseURLString: \(domain.baseURLString)")
    }
    return url
  }
  var path: String { domain.url + urlPath }

  var headers: [String: String]? { APIHeaders.cached }

  var task: Moya.Task {
    if let parameters {
      return method == .get
        ? .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        : .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    return .requestPlain
  }
}

// 순수 캐시
public enum APIHeaders {
  static let cached: [String: String] = [
    "Content-Type": "application/json"
  ]
}
