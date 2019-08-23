//
//  Operations.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public struct CreateAccountOp: XDRCodable, XDREncodableStruct {
    let destination: PublicKey
    let balance: Int64

    public init(from decoder: XDRDecoder) throws {
        destination = try decoder.decode(PublicKey.self)
        balance = try decoder.decode(Int64.self)
    }

    init(destination: PublicKey, balance: Int64) {
        self.destination = destination
        self.balance = balance
    }
}

extension CreateAccountOp: Encodable {}

struct PaymentOp: XDRCodable, XDREncodableStruct {
    let destination: PublicKey
    let asset: Asset
    let amount: Int64

    init(from decoder: XDRDecoder) throws {
        destination = try decoder.decode(PublicKey.self)
        asset = try decoder.decode(Asset.self)
        amount = try decoder.decode(Int64.self)
    }

    init(destination: PublicKey, asset: Asset, amount: Int64) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
    }
}

extension PaymentOp: Encodable {}

public struct PathPaymentOp: XDRCodable, XDREncodableStruct {
    let sendAsset: Asset
    let sendMax: Int64
    let destination: PublicKey
    let destAsset: Asset
    let destAmount: Int64
    let path: Array<Asset>

    public init(from decoder: XDRDecoder) throws {
        sendAsset = try decoder.decode(Asset.self)
        sendMax = try decoder.decode(Int64.self)
        destination = try decoder.decode(PublicKey.self)
        destAsset = try decoder.decode(Asset.self)
        destAmount = try decoder.decode(Int64.self)
        path = try decoder.decode([Asset].self)
    }
}

public struct ChangeTrustOp: XDRCodable, XDREncodableStruct {
    let asset: Asset
    let limit: Int64

    public init(from decoder: XDRDecoder) throws {
        asset = try decoder.decode(Asset.self)
        limit = try decoder.decode(Int64.self)
    }

    public init(asset: Asset, limit: Int64 = Int64.max) {
        self.asset = asset
        self.limit = limit
    }
}

public struct AllowTrustOp: XDRCodable, XDREncodableStruct {
    let trustor: PublicKey
    let asset: Data
    let authorize: Bool

    public init(from decoder: XDRDecoder) throws {
        trustor = try decoder.decode(PublicKey.self)

        let discriminant = try decoder.decode(Int32.self)
        if discriminant == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4 {
            asset = try Data(decoder.read(4))
        }
        else if discriminant == AssetType.ASSET_TYPE_CREDIT_ALPHANUM12 {
            asset = try Data(decoder.read(12))
        }
        else {
            fatalError("Unsupported asset type: \(discriminant)")
        }

        authorize = try decoder.decode(Bool.self)
    }
}

public struct SetOptionsOp: XDRCodable {
    let inflationDest: PublicKey?
    let clearFlags: UInt32?
    let setFlags: UInt32?
    let masterWeight: UInt32?
    let lowThreshold: UInt32?
    let medThreshold: UInt32?
    let highThreshold: UInt32?
    let homeDomain: String?
    let signer: Signer?

    public init(from decoder: XDRDecoder) throws {
        inflationDest = try decoder.decode(PublicKey?.self)
        clearFlags = try decoder.decode(UInt32?.self)
        setFlags = try decoder.decode(UInt32?.self)
        masterWeight = try decoder.decode(UInt32?.self)
        lowThreshold = try decoder.decode(UInt32?.self)
        medThreshold = try decoder.decode(UInt32?.self)
        highThreshold = try decoder.decode(UInt32?.self)
        homeDomain = try decoder.decode(String?.self)
        signer = try decoder.decode(Signer?.self)
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(inflationDest)
        try encoder.encode(clearFlags)
        try encoder.encode(setFlags)
        try encoder.encode(masterWeight)
        try encoder.encode(lowThreshold)
        try encoder.encode(medThreshold)
        try encoder.encode(highThreshold)
        try encoder.encode(homeDomain)
        try encoder.encode(signer)
    }
}

extension SetOptionsOp: Encodable {}

public struct ManageOfferOp: XDRCodable, XDREncodableStruct {
    let buying: Asset
    let selling: Asset
    let amount: Int64
    let price: Price
    let offerId: Int64

    public init(from decoder: XDRDecoder) throws {
        buying = try decoder.decode(Asset.self)
        selling = try decoder.decode(Asset.self)
        amount = try decoder.decode(Int64.self)
        price = try decoder.decode(Price.self)
        offerId = try decoder.decode(Int64.self)
    }
}

public struct CreatePassiveOfferOp: XDRCodable, XDREncodableStruct {
    let buying: Asset
    let selling: Asset
    let amount: Int64
    let price: Price

    public init(from decoder: XDRDecoder) throws {
        buying = try decoder.decode(Asset.self)
        selling = try decoder.decode(Asset.self)
        amount = try decoder.decode(Int64.self)
        price = try decoder.decode(Price.self)
    }
}

public struct AccountMergeOp: XDRCodable, XDREncodableStruct {
    let destination: PublicKey

    public init(from decoder: XDRDecoder) throws {
        destination = try decoder.decode(PublicKey.self)
    }
}

public struct ManageDataOp: XDRCodable {
    let dataName: String
    let dataValue: Data?

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(dataName)
        try encoder.encode(dataValue)
    }

    public init(from decoder: XDRDecoder) throws {
        dataName = try decoder.decode(String.self)

        dataValue = try decoder.decode(Bool.self)
            ? try decoder.decode(Data.self)
            : nil
    }

    public init(dataName: String, dataValue: Data?) {
        self.dataName = dataName
        self.dataValue = dataValue
    }
}

extension ManageDataOp: Encodable {}

public struct Signer: XDRCodable, XDREncodableStruct {
    let key: SignerKey
    let weight: UInt32

    public init(from decoder: XDRDecoder) throws {
        key = try decoder.decode(SignerKey.self)
        weight = try decoder.decode(UInt32.self)
    }
}

extension Signer: Encodable {}

public struct Price: XDRDecodable {
    let n: Int32
    let d: Int32

    public init(from decoder: XDRDecoder) throws {
        n = try decoder.decode(Int32.self)
        d = try decoder.decode(Int32.self)
    }
}

