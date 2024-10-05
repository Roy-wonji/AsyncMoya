//
//  Extension+MoyaProvider.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation
import Combine

import Moya
import CombineMoya


import RxMoya
import RxSwift

import LogMacro

@MainActor
extension MoyaProvider {
    //MARK: - MoyaProvider에 요청을 비동기적으로 처리하는 확장 함수 추가 Sendable swift6 에서 데이터 Race checking 때매 체택
    public func requestAsync<T: Decodable & Sendable>(
        _ target: Target,
        decodeTo type: T.Type
    ) async throws ->  T {
        return try await withCheckedThrowingContinuation { continuation in
            // async/await API의 일부로, 비동기 작업을 동기식으로 변환할 때 사용됩니다. 여기서 continuation은 비동기 작업이 완료되면 값을 반환하거나 오류를 던지기 위해 사용
            var cancellable: AnyCancellable?
            cancellable = self.requestPublisher(target)
                .tryMap { response -> Data in
                    guard let httpResponse = response.response else {
                        throw DataError.noData
                    }
                    switch httpResponse.statusCode {
                    case 200, 201, 204, 401:
                        return response.data
                    case 400:
                        throw MoyaError.statusCode(response)
                    case 404:
                        let errorResponse = try response.data.decoded(as: ResponseError.self)
                        throw DataError.customError(errorResponse)
                    default:
                        throw DataError.unhandledStatusCode(httpResponse.statusCode)
                    }
                }
                .tryCompactMap { data -> T? in
                    if data.isEmpty {
                        return nil
                    }
                    return try data.decoded(as: T.self)
                }
                .mapError { error -> MoyaError in
                    if let moyaError = error as? MoyaError {
                        Log.error("MoyaError occurred: \(moyaError.localizedDescription)")
                        if case .statusCode(let response) = moyaError, response.statusCode == 400{
                            #logError("400 토큰 인증실패: triggering retry logic")
                            return moyaError
                        }
                        return moyaError
                    } else if let decodingError = error as? DecodingError {
                        #logError("DecodingError occurred: \(decodingError.localizedDescription)")
                        return MoyaError.underlying(decodingError, nil)
                    } else if let dataError = error as? DataError {
                        #logError("DataError occurred: \(dataError.localizedDescription)")
                        return MoyaError.underlying(dataError, nil)
                    } else {
                        let unknownError = NSError(domain: "Unknown Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."])
                        Log.error("Unknown error occurred")
                        return MoyaError.underlying(unknownError, nil)
                    }
                }
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                        cancellable?.cancel()
                        #logError("네트워크 에러", error)
                    }
                }, receiveValue: {  decodedObject in
                    continuation.resume(returning: decodedObject)
                    #logNetwork("\(type) 데이터 통신", decodedObject)
                })
        }
    }
    
    //MARK: -  컴바인을 제거하고 Async/Await 으로 만 사용
    public func requestAsyncAwait<T: Decodable & Sendable>(
        _ target: Target,
        decodeTo type: T.Type
    ) async throws -> T {
        // async/await API의 일부로, 비동기 작업을 동기식으로 변환할 때 사용됩니다. 여기서 continuation은 비동기 작업이 완료되면 값을 반환하거나 오류를 던지기 위해 사용
        return try await withCheckedThrowingContinuation { continuation in
            // MoyaProvider를 사용해 비동기 요청 처리
            self.request(target) { result in
                let finalResult: Result<T, Error>
                switch result {
                case .success(let response):
                    guard let httpResponse = response.response else {
                        finalResult = .failure(DataError.noData)
                        break
                    }
                    // HTTP 상태 코드에 따른 처리
                    switch httpResponse.statusCode {
                    case 200, 201, 204, 401:
                        // 정상 상태 코드
                        if response.data.isEmpty, T.self == Void.self {
                            finalResult = .success(Void() as! T)
                        } else {
                            let decodeResult: Result<T, Error> = Result {
                                try response.data.decoded(as: T.self)
                            }.mapError { error in
                                #logError("DecodingError occurred: \(error.localizedDescription)")
                                return MoyaError.underlying(error, nil)
                            }
                            finalResult = decodeResult
                        }
                    case 400:
                        finalResult = .failure(MoyaError.statusCode(response))
                    case 404:
                        let errorDecodeResult: Result<ResponseError, Error> = Result {
                            try response.data.decoded(as: ResponseError.self)
                        }.mapError { error in
                            return MoyaError.underlying(error, nil)
                        }
                        switch errorDecodeResult {
                        case .success(let errorResponse):
                            finalResult = .failure(DataError.customError(errorResponse))
                        case .failure(let error):
                            finalResult = .failure(error)
                        }
                    default:
                        finalResult = .failure(DataError.unhandledStatusCode(httpResponse.statusCode))
                    }

                case .failure(let error):
                    finalResult = .failure(error)
                }

                // Result에 따라 continuation 종료
                switch finalResult {
                case .success(let value):
                    continuation.resume(returning: value)
                    #logNetwork("\(type) 데이터 통신", value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                    #logError("네트워크 에러 발생: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: - MoyaProvider에 요청을 AsyncThrowingStream 비동기적으로 처리하는 확장 함수 추가
    public func requestAsyncThrowingStream<T: Decodable & Sendable>(
        _ target: Target,
        decodeTo type: T.Type
    ) -> AsyncThrowingStream<T, Error> {
        // 퍼블리셔를 미리 준비합니다.
        let provider = MoyaProvider<Target>()
        let publisher = provider.requestPublisher(target)
            .tryMap { response -> Data in
                guard let httpResponse = response.response else {
                    throw DataError.noData
                }
                switch httpResponse.statusCode {
                case 200, 201, 204, 401:
                    return response.data
                case 400:
                    throw DataError.badRequest
                case 404:
                    let errorResponse = try response.data.decoded(as: ResponseError.self)
                    throw DataError.customError(errorResponse)
                default:
                    throw DataError.unhandledStatusCode(httpResponse.statusCode)
                }
            }
            .tryCompactMap { data -> T?  in
                if data.isEmpty {
                    return nil
                }
                return try data.decoded(as: T.self)
            }
            .mapError { error in
                if let moyaError = error as? MoyaError {
                    return DataError.moyaError(moyaError)
                } else if let decodingError = error as? DecodingError {
                    return DataError.decodingError(decodingError)
                } else if let dataError = error as? DataError {
                    return dataError
                } else {
                    return DataError.unknownError
                }
            }
            .eraseToAnyPublisher()
        
        // AsyncThrowingStream을 생성하고 반환합니다.
        return AsyncThrowingStream { continuation in
            nonisolated(unsafe) var cancellable: AnyCancellable?
            
            cancellable = publisher.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { decodedObject in
                    continuation.yield(decodedObject)
                    Log.network("\(type) 데이터 통신", decodedObject)
                }
            )
            
            continuation.onTermination = { @Sendable (async) in
                cancellable?.cancel()
            }
        }
    }
    
    //MARK: - MoyaProvider에 요청을 AsyncStream 비동기적으로 처리하는 확장 함수 추가
    public func requestAsyncStream<T: Decodable & Sendable>(
        _ target: Target,
        decodeTo type: T.Type
    ) -> AsyncStream<Result<T, Error>> {
            // 퍼블리셔를 미리 준비합니다.
            let provider = MoyaProvider<Target>()
            let publisher = provider.requestPublisher(target)
                .tryMap { response -> Data in
                    guard let httpResponse = response.response else {
                        throw DataError.noData
                    }
                    switch httpResponse.statusCode {
                    case 200, 201, 204, 401:
                        return response.data
                    case 400:
                        throw DataError.badRequest
                    case 404:
                        let errorResponse = try response.data.decoded(as: ResponseError.self)
                        throw DataError.customError(errorResponse)
                    default:
                        throw DataError.unhandledStatusCode(httpResponse.statusCode)
                    }
                }
                .tryCompactMap { data -> T?  in
                    if data.isEmpty {
                        return nil
                    }
                    return try data.decoded(as: T.self)
                }
                .mapError { error in
                    if let moyaError = error as? MoyaError {
                        return DataError.moyaError(moyaError)
                    } else if let decodingError = error as? DecodingError {
                        return DataError.decodingError(decodingError)
                    } else if let dataError = error as? DataError {
                        return dataError
                    } else {
                        return DataError.unknownError
                    }
                }
            // AsyncStream을 생성하고 반환합니다.
            return AsyncStream { continuation in
                nonisolated(unsafe) var cancellable: AnyCancellable?
                
                cancellable = publisher.sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.finish()
                        case .failure(let error):
                            continuation.yield(.failure(error))
                            continuation.finish()
                        }
                    },
                    receiveValue: {  decodedObject in
                        continuation.yield(.success(decodedObject))
                        #logNetwork("\(type) 데이터 통신", decodedObject)
                    }
                )
                
                continuation.onTermination = { @Sendable (async) in
                    cancellable?.cancel()
                }
            }
        }
    
    //MARK: - RxSingle 통신 방식
    public func requestRxSingle<T: Decodable>(
        _ target: Target,
        decodeTo type: T.Type
    ) -> Single<T> {
            return self.rx.request(target)
                .observe(on: MainScheduler.instance)
                .flatMap { response -> Single<T> in
                    do {
                        let decodedObject = try response.data.decoded(as: T.self)
                        return .just(decodedObject)
                    } catch let decodingError {
                        #logError("Decoding error: \(decodingError.localizedDescription)")
                        return .error(decodingError)
                    }
                }
                .catch { error in
                    if let moyaError = error as? MoyaError {
                        Log.error("MoyaError occurred: \(moyaError.localizedDescription)")
                        if case .statusCode(let response) = moyaError, response.statusCode == 400 {
                            #logError("400 토큰 인증실패: triggering retry logic")
                        }
                        return .error(moyaError)
                    } else {
                        let unknownError = NSError(
                            domain: "Unknown Error",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                        )
                        #logError("Unknown error occurred")
                        return .error(MoyaError.underlying(unknownError, nil))
                    }
                }
                .do(onSuccess: { data in
                    #logNetwork("\(type) 데이터 통신", data)
                }, onError: { error in
                    #logError("네트워크 에러", error.localizedDescription)
                })
        }
    
    //MARK: - RxObservable 통신 방식
    public func requestRxObservable<T: Decodable>(
        _ target: Target,
        decodeTo type: T.Type
    ) -> Observable<T> {
        return self.rx.request(target)
            .observe(on: MainScheduler.instance)
            .asObservable()
            .flatMap { response -> Observable<T> in
                do {
                    let decodedObject = try response.data.decoded(as: T.self)
                    return .just(decodedObject)
                } catch let decodingError {
                    #logError("디코딩 에러: \(decodingError.localizedDescription)")
                    return .error(decodingError)
                }
            }
            .catch { error in
                // Handle errors from Moya
                if let moyaError = error as? MoyaError {
                    #logError("MoyaError occurred: \(moyaError.localizedDescription)")
                    if case .statusCode(let response) = moyaError, response.statusCode == 400 {
                        #logError("400 토큰 인증실패: triggering retry logic")
                    }
                    return .error(moyaError) 
                } else {
                    let unknownError = NSError(
                        domain: "Unknown Error",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                    )
                    Log.error("Unknown error occurred")
                    return .error(MoyaError.underlying(unknownError, nil))
                }
            }
            .do(onNext: { data in
                #logNetwork("\(type) 데이터 통신", data)
            }, onError: { error in
                #logError("네트워크 에러", error.localizedDescription)
            })
    }
}
