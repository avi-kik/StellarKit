//
// History.swift
// StellarKit
//
// Created by Kin Foundation.
// Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public typealias Hash = WrappedData32

public enum Upgrade: XDRDecodable {
    case LEDGER_UPGRADE_VERSION(UInt32)
    case LEDGER_UPGRADE_BASE_FEE(UInt32)
    case LEDGER_UPGRADE_MAX_TX_SET_SIZE(UInt32)
    case LEDGER_UPGRADE_BASE_RESERVE(UInt32)

    public init(from decoder: XDRDecoder) throws {
        let d = try decoder.decode(UInt32.self)
        let v = try decoder.decode(UInt32.self)

        switch d {
        case 1: self = .LEDGER_UPGRADE_VERSION(v)
        case 2: self = .LEDGER_UPGRADE_BASE_FEE(v)
        case 3: self = .LEDGER_UPGRADE_MAX_TX_SET_SIZE(v)
        case 4: self = .LEDGER_UPGRADE_BASE_RESERVE(v)
        default: fatalError("Unknown upgrade")
        }
    }
}

extension Upgrade: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .LEDGER_UPGRADE_VERSION(let v):
            try container.encode(["version": v])
        case .LEDGER_UPGRADE_BASE_FEE(let v):
            try container.encode(["base_fee": v])
        case .LEDGER_UPGRADE_MAX_TX_SET_SIZE(let v):
            try container.encode(["max_tx_set_size": v])
        case .LEDGER_UPGRADE_BASE_RESERVE(let v):
            try container.encode(["base_reserve": v])
        }
    }
}

public struct StellarValue: XDRDecodable, XDREncodableStruct {
    public let txSetHash: Hash
    public let closeTime: UInt64
    public let upgrades: [Upgrade]
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        txSetHash = try decoder.decode(Hash.self)
        closeTime = try decoder.decode(UInt64.self)
        upgrades = try decoder.decode([Data].self)
            .map { try XDRDecoder(data: $0).decode(Upgrade.self) }

        _ = try decoder.decode(Int32.self)
    }
}

extension StellarValue: Encodable {}

public struct LedgerHeader: XDRDecodable, XDREncodable {
    public let ledgerVersion: UInt32
    public let previousLedgerHash: Hash
    public let scpValue: StellarValue
    public let txSetResultHash: Hash
    public let bucketListHash: Hash
    public let ledgerSeq: UInt32
    public let totalCoins: Int64
    public let feePool: Int64
    public let inflationSeq: UInt32
    public let idPool: UInt64
    public let baseFee: UInt32
    public let baseReserve: UInt32
    public let maxTxSetSize: UInt32
    public let skipList: WrappedArray4<Hash>
    let reserved: Int32 = 0

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(ledgerVersion)
        try encoder.encode(previousLedgerHash)
        try encoder.encode(scpValue)
        try encoder.encode(txSetResultHash)
        try encoder.encode(bucketListHash)
        try encoder.encode(ledgerSeq)
        try encoder.encode(totalCoins)
        try encoder.encode(feePool)
        try encoder.encode(inflationSeq)
        try encoder.encode(idPool)
        try encoder.encode(baseFee)
        try encoder.encode(baseReserve)
        try encoder.encode(maxTxSetSize)
        try encoder.encode(skipList)
        try encoder.encode(reserved)
    }

    public init(from decoder: XDRDecoder) throws {
        ledgerVersion = try decoder.decode(UInt32.self)
        previousLedgerHash = try decoder.decode(Hash.self)
        scpValue = try decoder.decode(StellarValue.self)
        txSetResultHash = try decoder.decode(Hash.self)
        bucketListHash = try decoder.decode(Hash.self)
        ledgerSeq = try decoder.decode(UInt32.self)
        totalCoins = try decoder.decode(Int64.self)
        feePool = try decoder.decode(Int64.self)
        inflationSeq = try decoder.decode(UInt32.self)
        idPool = try decoder.decode(UInt64.self)
        baseFee = try decoder.decode(UInt32.self)
        baseReserve = try decoder.decode(UInt32.self)
        maxTxSetSize = try decoder.decode(UInt32.self)
        skipList = try decoder.decode(WrappedArray4<Hash>.self)
        _ = try decoder.decode(Int32.self)
    }
}

extension LedgerHeader: Encodable {}

public struct LedgerHeaderHistoryEntry: XDRDecodable {
    public let hash: Hash
    public let header: LedgerHeader
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        hash = try decoder.decode(Hash.self)
        header = try decoder.decode(LedgerHeader.self)
        _ = try decoder.decode(Int32.self)
    }
}

extension LedgerHeaderHistoryEntry: Encodable {}

public struct TransactionHistoryEntry: XDRDecodable {
    public let ledgerSeq: UInt32
    public let txSet: TransactionSet
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        ledgerSeq = try decoder.decode(UInt32.self)
        txSet = try decoder.decode(TransactionSet.self)
        _ = try decoder.decode(Int32.self)
    }
}

extension TransactionHistoryEntry: Encodable {}

public struct TransactionSet: XDRDecodable {
    let previousLedgerHash: Hash
    let txs: [TransactionEnvelope]

    public init(from decoder: XDRDecoder) throws {
        previousLedgerHash = try decoder.decode(Hash.self)
        txs = try decoder.decode([TransactionEnvelope].self)
    }
}

extension TransactionSet: Encodable {}

public struct TransactionHistoryResultEntry: XDRDecodable {
    let ledgerSeq: UInt32
    let txResultSet: TransactionResultSet
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        ledgerSeq = try decoder.decode(UInt32.self)
        txResultSet = try decoder.decode(TransactionResultSet.self)
        _ = try decoder.decode(Int32.self)
    }
}

extension TransactionHistoryResultEntry: Encodable {}

struct TransactionResultSet: XDRDecodable {
    let results: [TransactionResultPair]

    public init(from decoder: XDRDecoder) throws {
        results = try decoder.decode([TransactionResultPair].self)
    }
}

extension TransactionResultSet: Encodable {}

struct TransactionResultPair: XDRDecodable {
    let transactionHash: Hash
    let result: TransactionResult

    public init(from decoder: XDRDecoder) throws {
        transactionHash = try decoder.decode(Hash.self)
        result = try decoder.decode(TransactionResult.self)
    }
}

extension TransactionResultPair: Encodable {}

public enum BucketEntry: XDRDecodable {
    case LIVEENTRY(LedgerEntry)
    case DEADENTRY(LedgerKey)

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(UInt32.self)

        switch discriminant {
        case 0: self = .LIVEENTRY(try decoder.decode(LedgerEntry.self))
        case 1: self = .DEADENTRY(try decoder.decode(LedgerKey.self))
        default: fatalError("Unexpected type: \(discriminant)")
        }

    }
}

extension BucketEntry: Encodable {
    enum CodingKeys: String, CodingKey {
        case LIVEENTRY, DEADENTRY
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .LIVEENTRY(let entry): try container.encode(entry, forKey: .LIVEENTRY)
        case .DEADENTRY(let key): try container.encode(key, forKey: .DEADENTRY)
        }
    }
}
