//
//  Extension+Data.swift
//  AsyncMoya
//
//  Created by Wonji Suh  on 10/3/24.
//

import Foundation

extension Data {
  //MARK: -  async/ await 으로 디코딩
  func decoded<T: Decodable>(as type: T.Type) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: self)
  }
}
