//
//  XDRCodable.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

public typealias XDRCodable = XDREncodable & XDRDecodable

public protocol XDREncodable {
    func encode(to encoder: XDREncoder) throws
}

public protocol XDRDecodable {
    init(from decoder: XDRDecoder) throws
}

public protocol XDREncodableStruct: XDREncodable { }

extension XDREncodableStruct {
    public func encode(to encoder: XDREncoder) throws {
        for (_, value) in Mirror(reflecting: self).children {
            if let value = value as? XDREncodable {
                try value.encode(to: encoder)
            }
        }
    }
}

public class XDREncoder {
    private var data = Data()

    public static func encode<T>(_ value: T) throws -> Data where T: XDREncodable {
        let encoder = XDREncoder()

        try encoder.encode(value)

        return encoder.data
    }

    public static func encode<T>(_ value: T?) throws -> Data where T: XDREncodable {
        let encoder = XDREncoder()

        try encoder.encode(value)

        return encoder.data
    }

    func encode<T>(_ value: T) throws where T: XDREncodable {
        try value.encode(to: self)
    }

    func encode<T>(_ value: T?) throws where T: XDREncodable {
        if let v = value {
            try self.encode(Int32(1))
            try v.encode(to: self)
        }
        else {
            try self.encode(Int32(0))
        }
    }

    fileprivate func append<S>(_ data: S) where S: Sequence, S.Element == Data.Iterator.Element {
        self.data.append(contentsOf: data)
    }
}

public class XDRDecoder {
    public enum Errors: Error {
        case prematureEndOfData
        case stringDecodingFailed(Data)
    }

    private let data: Data
    private var cursor: Int = 0

    public static func decode<T: XDRDecodable>(_ type: T.Type, data: Data) throws -> T {
        let decoder = XDRDecoder(data: data)
        return try decoder.decode(type)
    }

    public static func decode<T: XDRDecodable>(_ type: T?.Type, data: Data) throws -> T? {
        let decoder = XDRDecoder(data: data)
        return try decoder.decode([T].self).first
    }

    public func decode<T: XDRDecodable>(_ type: T.Type) throws -> T {
        return try type.init(from: self)
    }

    public func decode<T: XDRDecodable>(_ type: T?.Type) throws -> T? {
        return try decode([T].self).first
    }

    public func decode<T: XDRDecodable>(_ type: [T].Type) throws -> [T] {
        return try (0 ..< decode(Int32.self)).map { _ in try T.self.init(from: self) }
    }

    public init(data: Data) {
        self.data = data
    }

    fileprivate func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws {
        guard cursor + byteCount <= data.count else { throw Errors.prematureEndOfData }

        data.withUnsafeBytes({ (ptr: UnsafePointer<UInt8>) -> () in
            let from = ptr + cursor
            memcpy(into, from, byteCount)
        })

        advance(by: byteCount)
    }

    fileprivate func read(_ count: Int) throws -> [UInt8] {
        guard cursor + count <= data.count else { throw Errors.prematureEndOfData }

        let bytes = data[cursor ..< cursor + count]
        advance(by: count)

        return bytes.map { $0 }
    }

    fileprivate func advance(by count: Int) { cursor += count }
}

extension Bool: XDRCodable {
    public init(from decoder: XDRDecoder) throws {
        self = try decoder.decode(UInt32.self) > 0
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(self ? UInt32(1) : UInt32(0))
    }
}

extension FixedWidthInteger where Self: XDRCodable {
    public init(from decoder: XDRDecoder) throws {
        var v = Self.init()
        try decoder.read(Self.bitWidth / 8, into: &v)
        self = Self.init(bigEndian: v)
    }

    public func encode(to encoder: XDREncoder) throws {
        var v = self.bigEndian

        withUnsafeBytes(of: &v) {
            encoder.append($0.map { $0 })
        }
    }
}

extension UInt8: XDRCodable { }
extension Int32: XDRCodable { }
extension UInt32: XDRCodable { }
extension Int64: XDRCodable { }
extension UInt64: XDRCodable { }

extension String: XDRCodable {
    public init(from decoder: XDRDecoder) throws {
        let data = try decoder.decode(Data.self)
        
        guard let s = String(bytes: data, encoding: .utf8) else {
            throw XDRDecoder.Errors.stringDecodingFailed(data)
        }

        self = s
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(self.data(using: .utf8)!)
    }
}

extension Data: XDRCodable {
    public init(from decoder: XDRDecoder) throws {
        let length = try Int32(from: decoder)

        self = try Data(bytes: decoder.read(Int(length)))

        decoder.advance(by: (4 - Int(count) % 4) % 4)
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(Int32(count))
        encoder.append(self)
        encoder.append(Array<UInt8>(repeating: 0, count: (4 - Int(count) % 4) % 4))
    }
}

extension Array: XDREncodable where Element: XDREncodable {
    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(Int32(count))
        try forEach { try $0.encode(to: encoder) }
    }
}
