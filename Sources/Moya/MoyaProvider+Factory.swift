//
//  MoyaProvider+Factory.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/3/24.
//

import Foundation
import Moya

/// MoyaProvider 편의 생성자 모음
extension MoyaProvider {
  /// 기본 Provider (로그 플러그인만 포함)
  public static var `default`: MoyaProvider {
    MoyaProvider(
      plugins: [
        MoyaLoggingPlugin()
      ]
    )
  }

  /// 커스텀 Alamofire.Session을 쓰는 Provider
  public static func withSession(_ session: RequestInterceptor) -> MoyaProvider {
    MoyaProvider(
      session: Session(interceptor: session),
      plugins: [
        MoyaLoggingPlugin()
      ]
    )
  }
}
