//
//  MoyaProvider+Rx.swift
//  AsyncMoya
//
//  Created by Wonji Suh on 10/3/24.
//

import Foundation

import Moya
import RxMoya
import RxSwift

import LogMacro

extension MoyaProvider {
  /// RxSwift Single을 사용한 네트워크 요청
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: 디코딩된 객체를 방출하는 `Single<T>`
  public func requestRxSingle<T: Decodable>(
    _ target: Target
  ) -> Single<T> {
    self.rx.request(target)
      .asObservable()
      .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
      .flatMap { response -> Observable<T> in
        let mapped: Result<T, Error> = ResponseMapper.map(.success(response))
        switch mapped {
        case .success(let value):
          return .just(value)
        case .failure(let error):
          #logError("네트워크 에러", error.localizedDescription)
          return .error(error)
        }
      }
      .catch { error in
        if let moyaError = error as? MoyaError {
          #logError("MoyaError occurred: \(moyaError.localizedDescription)")
          return .error(moyaError)
        }
        let unknownError = NSError(
          domain: "Unknown Error",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
        )
        #logError("Unknown error occurred")
        return .error(unknownError)
      }
      .do(
        onNext: { data in
          #logNetwork("\(T.self) 데이터 통신", data)
        },
        onError: { error in
          #logError("네트워크 에러", error.localizedDescription)
        }
      )
      .asSingle()
  }
  
  /// RxSwift Observable을 사용한 네트워크 요청
  ///
  /// - Parameter target: 호출할 Moya `Target` 엔드포인트
  /// - Returns: 디코딩된 객체들을 방출하는 `Observable<T>`
  public func requestRxObservable<T: Decodable>(
    _ target: Target
  ) -> Observable<T> {
    self.rx.request(target)
      .observe(on: MainScheduler.instance)
      .asObservable()
      .throttle(.milliseconds(300), latest: true, scheduler: MainScheduler.asyncInstance)
      .flatMap { response -> Observable<T> in
        let mapped: Result<T, Error> = ResponseMapper.map(.success(response))
        switch mapped {
        case .success(let value):
          return .just(value)
        case .failure(let error):
          #logError("네트워크 에러", error.localizedDescription)
          return .error(error)
        }
      }
      .catch { error in
        if let moyaError = error as? MoyaError {
          #logError("MoyaError occurred: \(moyaError.localizedDescription)")
          return .error(moyaError)
        }
        let unknownError = NSError(
          domain: "Unknown Error",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
        )
        #logError("Unknown error occurred")
        return .error(unknownError)
      }
      .do(
        onNext: { data in
          #logNetwork("\(T.self) 데이터 통신", data)
        },
        onError: { error in
          #logError("네트워크 에러", error.localizedDescription)
        }
      )
  }
}
