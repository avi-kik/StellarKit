//
//  Transaction.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

struct MemoType {
    static let MEMO_NONE: Int32 = 0
    static let MEMO_TEXT: Int32 = 1
    static let MEMO_ID: Int32 = 2
    static let MEMO_HASH: Int32 = 3
    static let MEMO_RETURN: Int32 = 4
}

public enum Memo: XDRCodable {
    case MEMO_NONE
    case MEMO_TEXT (String)
    case MEMO_ID (UInt64)
    case MEMO_HASH (Data)
    case MEMO_RETURN (Data)

    public var text: String? {
        if case let .MEMO_TEXT(text) = self {
            return text
        }

        if case let .MEMO_HASH(data) = self, let s = String(data: data, encoding: .utf8) {
            return s
        }

        return nil
    }

    public var data: Data? {
        if case let .MEMO_HASH(data) = self {
            return data
        }

        return nil
    }

    public init(_ string: String) throws {
        guard string.utf8.count <= 28 else {
            throw StellarError.memoTooLong(string)
        }

        self = .MEMO_TEXT(string)
    }

    public init(_ data: Data) throws {
        guard data.count <= 32 else {
            throw StellarError.memoTooLong(data)
        }

        self = .MEMO_HASH(data)
    }

    private func discriminant() -> Int32 {
        switch self {
        case .MEMO_NONE: return MemoType.MEMO_NONE
        case .MEMO_TEXT: return MemoType.MEMO_TEXT
        case .MEMO_ID: return MemoType.MEMO_ID
        case .MEMO_HASH: return MemoType.MEMO_HASH
        case .MEMO_RETURN: return MemoType.MEMO_RETURN
        }
    }

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case MemoType.MEMO_NONE:
            self = .MEMO_NONE
        case MemoType.MEMO_ID:
            self = .MEMO_ID(try decoder.decode(UInt64.self))
        case MemoType.MEMO_TEXT:
            self = .MEMO_TEXT(try decoder.decode(String.self))
        case MemoType.MEMO_HASH:
            self = .MEMO_HASH(try decoder.decode(WrappedData32.self).wrapped)
        default:
            self = .MEMO_NONE
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())

        switch self {
        case .MEMO_NONE: break
        case .MEMO_TEXT (let text): try encoder.encode(text)
        case .MEMO_ID (let id): try encoder.encode(id)
        case .MEMO_HASH (let hash): try encoder.encode(WrappedData32(hash))
        case .MEMO_RETURN (let hash): try encoder.encode(WrappedData32(hash))
        }
    }
}

extension Memo: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .MEMO_NONE: try container.encode("")
        case .MEMO_TEXT(let string): try container.encode(string)
        case .MEMO_HASH(let data): try container.encode(data.hexString)
        case .MEMO_RETURN(let data): try container.encode(data.hexString)
        case .MEMO_ID(let id): try container.encode(id)
        }
    }
}

public struct TimeBounds: XDRCodable, XDREncodableStruct {
    let minTime: UInt64
    let maxTime: UInt64

    public init(minTime: UInt64, maxTime: UInt64) {
        self.minTime = minTime
        self.maxTime = maxTime
    }

    public init(from decoder: XDRDecoder) throws {
        minTime = try decoder.decode(UInt64.self)
        maxTime = try decoder.decode(UInt64.self)
    }
}

extension TimeBounds: Encodable {}

public struct Transaction: XDRCodable {
    var sourceAccount: PublicKey
    var fee: UInt32
    var seqNum: UInt64
    var timeBounds: TimeBounds?
    var memo: Memo
    var operations: [Operation]
    let reserved: Int32 = 0

    var memoString: String? {
        if case let Memo.MEMO_TEXT(text) = memo {
            return text
        }

        return nil
    }

    public init(sourceAccount: StellarKey,
                seqNum: UInt64,
                timeBounds: TimeBounds?,
                memo: Memo,
                fee: UInt32,
                operations: [Operation]) {
        self.init(sourceAccount: PublicKey(sourceAccount),
                  seqNum: seqNum,
                  timeBounds: timeBounds,
                  memo: memo,
                  fee: fee,
                  operations: operations)
    }

    init(sourceAccount: PublicKey,
         seqNum: UInt64,
         timeBounds: TimeBounds?,
         memo: Memo,
         fee: UInt32,
         operations: [Operation]) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.fee = fee
        self.operations = operations
    }

    public init(from decoder: XDRDecoder) throws {
        sourceAccount = try decoder.decode(PublicKey.self)
        fee = try decoder.decode(UInt32.self)
        seqNum = try decoder.decode(UInt64.self)
        timeBounds = try decoder.decode(TimeBounds?.self)
        memo = try decoder.decode(Memo.self)
        operations = try decoder.decode([Operation].self)
        _ = try decoder.decode(Int32.self)
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(sourceAccount)
        try encoder.encode(fee)
        try encoder.encode(seqNum)
        try encoder.encode(timeBounds)
        try encoder.encode(memo)
        try encoder.encode(operations)
        try encoder.encode(reserved)
    }
    
    public func hash(networkId: String) throws -> [UInt8] {
        let payload = try TransactionSignaturePayload(tx: self, networkId: networkId)
        return try XDREncoder.encode(payload).sha256
    }
}

extension Transaction: Encodable {}

struct EnvelopeType {
    static let ENVELOPE_TYPE_SCP: Int32 = 1
    static let ENVELOPE_TYPE_TX: Int32 = 2
    static let ENVELOPE_TYPE_AUTH: Int32 = 3
}

public struct TransactionSignaturePayload: XDREncodableStruct {
    let networkId: WrappedData32
    let taggedTransaction: TaggedTransaction

    var tx: Transaction? {
        if case let .ENVELOPE_TYPE_TX(tx) = taggedTransaction {
            return tx
        }

        return nil
    }

    enum TaggedTransaction: XDREncodable {
        case ENVELOPE_TYPE_TX (Transaction)

        private func discriminant() -> Int32 {
            switch self {
            case .ENVELOPE_TYPE_TX: return EnvelopeType.ENVELOPE_TYPE_TX
            }
        }

        func encode(to encoder: XDREncoder) throws {
            try encoder.encode(discriminant())

            switch self {
            case .ENVELOPE_TYPE_TX (let tx): try encoder.encode(tx)
            }
        }
    }

    public init(tx: Transaction, networkId: String) throws {
        guard let data = networkId.data(using: .utf8)?.sha256 else {
            throw StellarError.dataEncodingFailed
        }

        self.networkId = WD32(data)
        taggedTransaction = .ENVELOPE_TYPE_TX(tx)
    }
}

public struct DecoratedSignature: XDRCodable, XDREncodableStruct, Equatable {
    let hint: WrappedData4;
    let signature: [UInt8]

    public init(from decoder: XDRDecoder) throws {
        hint = try decoder.decode(WrappedData4.self)
        signature = try decoder.decode([UInt8].self)
    }

    init(hint: WrappedData4, signature: [UInt8]) {
        self.hint = hint
        self.signature = signature
    }
}

extension DecoratedSignature: Encodable {
    enum CodingKeys: String, CodingKey {
        case hint
        case signature
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hint.wrapped.hexString, forKey: .hint)
        try container.encode(Data(signature).base64EncodedString(), forKey: .signature)
    }
}

public struct TransactionEnvelope: XDRCodable, XDREncodableStruct {
    let tx: Transaction
    private(set) var signatures: [DecoratedSignature]

    public init(from decoder: XDRDecoder) throws {
        tx = try decoder.decode(Transaction.self)
        signatures = try decoder.decode([DecoratedSignature].self)
    }

    public init(tx: Transaction, signatures: [DecoratedSignature]) {
        self.tx = tx
        self.signatures = signatures
    }
}

extension TransactionEnvelope: Encodable {}

extension TransactionEnvelope {
    public mutating func add(signature: DecoratedSignature) {
        if !signatures.contains(signature) { signatures.append(signature) }
    }
}
