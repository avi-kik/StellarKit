//
//  PublicKey.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

struct CryptoKeyType {
    static let KEY_TYPE_ED25519: Int32 = 0
    static let KEY_TYPE_PRE_AUTH_TX: Int32 = 1
    static let KEY_TYPE_HASH_X: Int32 = 2
}

struct PublicKeyType {
    static let PUBLIC_KEY_TYPE_ED25519 = CryptoKeyType.KEY_TYPE_ED25519
}

enum PublicKey: XDRCodable, Equatable {
    case PUBLIC_KEY_TYPE_ED25519 (WrappedData32)

    var publicKey: String {
        if case .PUBLIC_KEY_TYPE_ED25519(let wrapper) = self {
            return StellarKey(wrapper.wrapped).description
        }

        fatalError("unknown public key type")
    }

    init(from decoder: XDRDecoder) throws {
        _ = try decoder.decode(Int32.self)

        self = .PUBLIC_KEY_TYPE_ED25519(try decoder.decode(WrappedData32.self))
    }

    init(_ keyData: WrappedData32) {
        self = .PUBLIC_KEY_TYPE_ED25519(keyData)
    }

    init(_ stellarKey: StellarKey) {
        self = .PUBLIC_KEY_TYPE_ED25519(WrappedData32(stellarKey.key))
    }
    
    private func discriminant() -> Int32 {
        return PublicKeyType.PUBLIC_KEY_TYPE_ED25519
    }
    
    func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())

        switch self {
        case .PUBLIC_KEY_TYPE_ED25519 (let key):
            try encoder.encode(key)
        }
    }

    public static func ==(lhs: PublicKey, rhs: PublicKey) -> Bool {
        switch (lhs, rhs) {
        case let (.PUBLIC_KEY_TYPE_ED25519(k1), .PUBLIC_KEY_TYPE_ED25519(k2)):
            return k1 == k2
        }
    }
}

extension PublicKey: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(publicKey)
    }
}

struct SignerKeyType {
    static let SIGNER_KEY_TYPE_ED25519 = CryptoKeyType.KEY_TYPE_ED25519
    static let SIGNER_KEY_TYPE_PRE_AUTH_TX = CryptoKeyType.KEY_TYPE_PRE_AUTH_TX
    static let SIGNER_KEY_TYPE_HASH_X = CryptoKeyType.KEY_TYPE_HASH_X
}

enum SignerKey: XDRCodable {
    case SIGNER_KEY_TYPE_ED25519 (WrappedData32)
    case SIGNER_KEY_TYPE_PRE_AUTH_TX (WrappedData32)
    case SIGNER_KEY_TYPE_HASH_X (WrappedData32)

    init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case SignerKeyType.SIGNER_KEY_TYPE_ED25519:
            self = .SIGNER_KEY_TYPE_ED25519(try decoder.decode(WrappedData32.self))
        case SignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
            self = .SIGNER_KEY_TYPE_PRE_AUTH_TX(try decoder.decode(WrappedData32.self))
        case SignerKeyType.SIGNER_KEY_TYPE_HASH_X:
            self = .SIGNER_KEY_TYPE_HASH_X(try decoder.decode(WrappedData32.self))
        default:
            self = .SIGNER_KEY_TYPE_ED25519(try decoder.decode(WrappedData32.self))
        }
    }

    private func discriminant() -> Int32 {
        switch self {
        case .SIGNER_KEY_TYPE_ED25519: return SignerKeyType.SIGNER_KEY_TYPE_ED25519
        case .SIGNER_KEY_TYPE_PRE_AUTH_TX: return SignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX
        case .SIGNER_KEY_TYPE_HASH_X: return SignerKeyType.SIGNER_KEY_TYPE_HASH_X
        }
    }

    func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())

        switch self {
        case .SIGNER_KEY_TYPE_ED25519 (let key): try encoder.encode(key)
        case .SIGNER_KEY_TYPE_PRE_AUTH_TX (let key): try encoder.encode(key)
        case .SIGNER_KEY_TYPE_HASH_X (let key): try encoder.encode(key)
        }
    }
}

extension SignerKey: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .SIGNER_KEY_TYPE_ED25519(let data):
            try container.encode(StellarKey(data.wrapped).description)
        case .SIGNER_KEY_TYPE_HASH_X(let data),
             .SIGNER_KEY_TYPE_PRE_AUTH_TX(let data):
            try container.encode(data.wrapped.hexString)
        }
    }
}
