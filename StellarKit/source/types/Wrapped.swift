//
//  Wrapped.swift
//  StellarKit
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

typealias WD4 = WrappedData4
typealias WD12 = WrappedData12
typealias WD32 = WrappedData32

private func decodeData(from decoder: XDRDecoder, capacity: Int) throws -> Data {
    var d = Data(capacity: capacity)

    for _ in 0 ..< capacity {
        let decoded = try UInt8.init(from: decoder)
        d.append(decoded)
    }

    return d
}

public protocol WrappedData: XDRCodable, Equatable, Encodable {
    static var capacity: Int { get }

    var wrapped: Data { get set }

    func encode(to encoder: XDREncoder) throws

    init()
    init<S: Sequence>(_ sequence: S) where S.Element == UInt8
}

extension WrappedData {
    public func encode(to encoder: XDREncoder) throws {
        try wrapped.forEach { try $0.encode(to: encoder) }
    }

    public init(from decoder: XDRDecoder) throws {
        self.init()
        wrapped = try decodeData(from: decoder, capacity: Self.capacity)
    }

    public init<S: Sequence>(_ sequence: S) where S.Element == UInt8 {
        self.init()

        let data = Data(sequence)

        self.wrapped = Data(repeating: 0, count: Self.capacity)
        self.wrapped[0 ..< min(data.count, Self.capacity)] = data
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped == rhs.wrapped
    }
}

extension WrappedData {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrapped.hexString)
    }
}

public struct WrappedData4: WrappedData {
    public static let capacity: Int = 4

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}

public struct WrappedData12: WrappedData {
    public static let capacity: Int = 12

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}

public struct WrappedData32: WrappedData {
    public static let capacity: Int = 32

    public var wrapped: Data

    public init() {
        wrapped = Data()
    }
}

public protocol WrappedArray: XDRCodable {
    associatedtype T: XDRCodable

    var capacity: Int { get }

    var wrapped: [T] { get set }

    init()
}

extension WrappedArray {
    public init(from decoder: XDRDecoder) throws {
        self.init()

        for _ in 0 ..< capacity { wrapped.append(try decoder.decode(T.self)) }
    }

    public func encode(to encoder: XDREncoder) throws {
        for x in wrapped { try encoder.encode(x) }
    }
}

public struct WrappedArray4<T: XDRCodable>: WrappedArray {
    public let capacity: Int = 4

    public var wrapped: [T]

    public init() {
        wrapped = []
    }
}

extension WrappedArray4: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrapped)
    }
}
