//
//  KeyUtils.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public enum KeyUtils {
    public static func base32(of key: [UInt8], type: KeyType) -> String {
        var d = [type.rawValue] + key

        d += d.crc16

        return Base32.encode(d)
    }

    public static func base32(publicKey: [UInt8]) -> String {
        return base32(of: publicKey, type: .ed25519PublicKey)
    }

    public static func base32(seed: [UInt8]) -> String {
        return base32(of: seed, type: .ed25519SecretSeed)
    }

    public static func key(base32: String) -> [UInt8] {
        // Stellar represents a key in base32 using a leading type identifier and a trailing 2-byte
        // checksum, for a total of 35 bytes.  The actual key is stored in bytes 2-33.

        return Array(Base32.decode(base32)[1 ..< 33])
    }

    public enum KeyType: UInt8 {
        case ed25519PublicKey = 48         // G (06 << 3)
        case ed25519SecretSeed = 144       // S (18 << 3)
        case preAuthTx = 152               // T (19 << 3)
        case sha256Hash =  184             // X (23 << 3)
    }
}
