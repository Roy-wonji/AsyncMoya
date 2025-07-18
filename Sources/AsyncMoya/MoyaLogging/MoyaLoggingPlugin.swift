//
//  MoyaLoggingPlugin.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Moya
import LogMacro

/// `Log.network`를 사용하여 네트워크 요청과 응답을 로깅하는 Moya 플러그인입니다.
///
/// - DEBUG 빌드에서만 활성화되어, 요청 전송 전(`willSend`)과 응답 수신 후(`didReceive`)에
///   HTTP 메서드, URL, 헤더, 본문 및 응답 데이터를 포맷된 메시지로 출력합니다.
public class MoyaLoggingPlugin: @preconcurrency PluginType {
  /// 플러그인 인스턴스를 생성합니다.
  public init() {}

  /// 전송될 `URLRequest`를 수정할 수 있습니다.
  ///
  /// - Parameters:
  ///   - request: 전송 직전의 `URLRequest` 객체
  ///   - target: 요청할 API 엔드포인트를 나타내는 `TargetType`
  /// - Returns: 실제로 전송할 `URLRequest`
  public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    return request
  }

  /// 요청이 전송되기 직전에 호출됩니다.
  ///
  /// HTTP 메서드, URL, 헤더, 요청 본문을 `Log.network`로 로깅합니다.
  ///
  /// - Parameters:
  ///   - request: 래핑된 `RequestType` 객체
  ///   - target: API 엔드포인트를 나타내는 `TargetType`
  @MainActor
  public func willSend(_ request: RequestType, target: TargetType) {
    guard let httpRequest = request.request else {
#if DEBUG
      #logNetwork("--> 유효하지 않은 요청입니다.", (Any).self)
#endif
      return
    }

    let method = httpRequest.httpMethod ?? "알 수 없는 HTTP 메서드"
    let url = httpRequest.description
    var log = """
⎡---------------------서버통신을 시작합니다.----------------------⎤
[\(method)] \(url)
API: \(target)
"""
    if let headers = httpRequest.allHTTPHeaderFields, !headers.isEmpty {
      log.append("\n헤더:\n \(headers)\n")
    }
    if let body = httpRequest.httpBody,
       let bodyString = String(data: body, encoding: .utf8) {
      log.append("\n본문:\n \(bodyString)\n")
    }
    log.append("⎣------------------ Request END  -------------------------⎦")

#if DEBUG
    #logNetwork("", log)
#endif
  }

  /// 응답을 받았을 때 호출됩니다.
  ///
  /// 성공 또는 실패 결과를 `onSucceed` 또는 `onFail`로 전달하여 로깅합니다.
  ///
  /// - Parameters:
  ///   - result: 성공 시 `Response`, 실패 시 `MoyaError`를 포함한 `Result`
  ///   - target: API 엔드포인트를 나타내는 `TargetType`
  @MainActor
  public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
    switch result {
    case let .success(response):
      onSucceed(response, target: target, isFromError: false)
    case let .failure(error):
      onFail(error, target: target)
    }
  }

  /// 응답을 처리하고 결과를 호출자에게 그대로 전달합니다.
  ///
  /// - Parameters:
  ///   - result: 원본 `Result<Response, MoyaError>`
  ///   - target: API 엔드포인트를 나타내는 `TargetType`
  /// - Returns: 호출자에게 전달할 동일한 `Result`
  public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
    return result
  }

  /// 성공 응답을 로깅합니다.
  ///
  /// - Parameters:
  ///   - response: 성공적으로 받은 `Response` 객체
  ///   - target: API 엔드포인트를 나타내는 `TargetType`
  ///   - isFromError: 에러 핸들러에서 전달된 응답인지 여부
  @MainActor
  public func onSucceed(_ response: Response, target: TargetType, isFromError: Bool) {
    let urlString = response.request?.url?.absoluteString ?? "알 수 없는 URL"
    let statusCode = response.statusCode
    var log = "⎡------------------서버에게 Response가 도착했습니다. ------------------⎤\n"
    log.append("API: \(target)\n")
    log.append("상태 코드: [\(statusCode)]\n")
    log.append("URL: \(urlString)\n")
    if let dataString = String(data: response.data, encoding: .utf8) {
      log.append("데이터:\n  \(dataString)\n")
    }
    log.append("⎣------------------ END HTTP (\(response.data.count)-byte body) ------------------⎦")
#if DEBUG
    #logNetwork("", log)
#endif
  }

  /// 실패 에러를 로깅합니다.
  ///
  /// - Parameters:
  ///   - error: 발생한 `MoyaError`
  ///   - target: API 엔드포인트를 나타내는 `TargetType`
  @MainActor
  public func onFail(_ error: MoyaError, target: TargetType) {
    if let response = error.response {
      // 응답을 포함한 에러는 성공 로깅으로 처리
      onSucceed(response, target: target, isFromError: true)
      return
    }
    var log = "⎡------------------ 네트워크 오류 ------------------⎤\n"
    log.append("오류 코드: \(error.errorCode) – 대상: \(target)\n")
    log.append("원인: \(error.failureReason ?? error.errorDescription ?? "알 수 없는 오류")\n")
    log.append("⎣------------------ 오류 종료 ------------------⎦")

#if DEBUG
    #logNetwork("", log)
#endif
  }
}
