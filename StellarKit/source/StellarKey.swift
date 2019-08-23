//
//  StellarKey.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public enum KeyType: UInt8 {
    case ed25519PublicKey = 48         // G (06 << 3)
    case ed25519SecretSeed = 144       // S (18 << 3)
    case preAuthTx = 152               // T (19 << 3)
    case sha256Hash =  184             // X (23 << 3)
}

public struct StellarKey: ExpressibleByStringLiteral, LosslessStringConvertible {
    public typealias StringLiteralType = String

    public let key: [UInt8]
    public let type: KeyType

    private let _string: String?
    public var description: String {
        return _string ?? {
            let d = [type.rawValue] + key

            return Base32.encode(d + d.crc16)
        }()
    }

    public init(stringLiteral value: StellarKey.StringLiteralType) {
        let data = Base32.decode(value)

        precondition(data.count == 35, "invalid length")

        let (key, crc) = (data[0 ..< 33], data[33...].array)
        guard key.crc16 == crc else { fatalError("invalid checksum") }

        guard let type = KeyType(rawValue: data[0]) else {
            fatalError("unknown type")
        }

        self.key = key.array
        self.type = type
        self._string = value
    }

    public init?(_ value: String) {
        let data = Base32.decode(value)

        guard data.count == 35 else { return nil }
        guard data[0 ..< 33].crc16 == data[33...].array else { return nil }

        guard let type = KeyType(rawValue: data[0]) else { return nil }

        self.key = data[1 ..< 33].array
        self.type = type
        self._string = value
    }

    public init<T: Collection>(_ bytes: T, type: KeyType = .ed25519PublicKey)
        where T.Element == UInt8
    {
        precondition(bytes.count == 32, "invalid key length")
        
        let r = bytes.startIndex ..< bytes.index(bytes.startIndex, offsetBy: 32)

        self.key = bytes[r].array
        self.type = type
        self._string = nil
    }
}
