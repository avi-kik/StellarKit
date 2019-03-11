//
// History.swift
// StellarKit
//
// Created by Kin Foundation.
// Copyright © 2019 Kin Foundation. All rights reserved.
//

import Foundation

typealias Hash = WrappedData32
typealias UpgradeType = Data

public struct StellarValue: XDRDecodable {
    let txSetHash: Hash
    let closeTime: UInt64
    let upgrades: [UpgradeType]
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        txSetHash = try decoder.decode(Hash.self)
        closeTime = try decoder.decode(UInt64.self)
        upgrades = try decoder.decode([Data].self)
        _ = try decoder.decode(Int32.self)
    }
}

extension StellarValue: Encodable {}

public struct LedgerHeader: XDRDecodable {
    let ledgerVersion: UInt32
    let previousLedgerHash: Hash
    let scpValue: StellarValue
    let txSetResultHash: Hash
    let bucketListHash: Hash
    let ledgerSeq: UInt32
    let totalCoins: Int64
    let feePool: Int64
    let inflationSeq: UInt32
    let idPool: UInt64
    let baseFee: UInt32
    let baseReserve: UInt32
    let maxTxSetSize: UInt32
    let skipList: [Hash]
    let reserved: Int32 = 0

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
        skipList = try decoder.decode(WrappedArray4<Hash>.self).wrapped
        _ = try decoder.decode(Int32.self)
    }
}

extension LedgerHeader: Encodable {}

public struct LedgerHeaderHistoryEntry: XDRDecodable {
    let hash: Hash
    let header: LedgerHeader
    let reserved: Int32 = 0

    public init(from decoder: XDRDecoder) throws {
        hash = try decoder.decode(Hash.self)
        header = try decoder.decode(LedgerHeader.self)
        _ = try decoder.decode(Int32.self)
    }
}

extension LedgerHeaderHistoryEntry: Encodable {}

public struct TransactionHistoryEntry: XDRDecodable {
    let ledgerSeq: UInt32
    let txSet: TransactionSet
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
