//
//  Watches.swift
//  StellarKit
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public struct Payment {
    public var source: String
    public var destination: String
    public var amount: Decimal
    public var asset: Asset
}

public struct TxEvent: Decodable, Equatable {
    public let hash: String
    public let created_at: Date
    public let source_account: String
    public let envelope: TransactionEnvelope
    public let meta: TransactionMeta

    enum CodingKeys: String, CodingKey {
        case hash
        case created_at
        case source_account
        case envelope = "envelope_xdr"
        case meta = "result_meta_xdr"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.hash = try container.decode(String.self, forKey: .hash)
        self.created_at = try container.decode(Date.self, forKey: .created_at)
        self.source_account = try container.decode(String.self, forKey: .source_account)

        let eb64 = try container.decode(String.self, forKey: .envelope)
        guard let ebData = Data(base64Encoded: eb64) else { throw StellarError.dataDecodingFailed }
        
        self.envelope = try XDRDecoder(data: ebData)
            .decode(TransactionEnvelope.self)

        let xb64 = try container.decode(String.self, forKey: .meta)
        guard let xbData = Data(base64Encoded: xb64) else { throw StellarError.dataDecodingFailed }

        self.meta = try XDRDecoder(data: xbData)
            .decode(TransactionMeta.self)
    }

    public static func ==(lhs: TxEvent, rhs: TxEvent) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension TxEvent {
    public var payments: [Payment] {
        return envelope.tx.operations.compactMap({ op in
            if case let Operation.Body.PAYMENT(pOP) = op.body {
                return Payment(source: op.sourceAccount?.publicKey ?? source_account,
                               destination: pOP.destination.publicKey,
                               amount: Decimal(pOP.amount),
                               asset: pOP.asset)
            }

            if case let Operation.Body.CREATE_ACCOUNT(cOP) = op.body {
                return Payment(source: op.sourceAccount?.publicKey ?? source_account,
                               destination: cOP.destination.publicKey,
                               amount: Decimal(cOP.balance),
                               asset: .ASSET_TYPE_NATIVE)
            }

            return nil
        })
    }
}

//MARK: -

public struct PaymentEvent: Decodable {
    fileprivate let source_account: String
    fileprivate let type: String
    fileprivate let type_i: Int32
    fileprivate let created_at: Date
    fileprivate let transaction_hash: String

    fileprivate let starting_balance: String?
    fileprivate let funder: String?
    fileprivate let account: String?

    fileprivate let asset_type: String?
    fileprivate let asset_code: String?
    fileprivate let asset_issuer: String?
    fileprivate let from: String?
    fileprivate let to: String?
    fileprivate let amountString: String?

    enum CodingKeys: String, CodingKey {
        case source_account = "source_account"
        case type = "type"
        case type_i = "type_i"
        case created_at = "created_at"
        case transaction_hash = "transaction_hash"
        case starting_balance = "starting_balance"
        case funder = "funder"
        case account = "account"
        case asset_type = "asset_type"
        case asset_code = "asset_code"
        case asset_issuer = "asset_issuer"
        case from = "from"
        case to = "to"
        case amountString = "amount"
    }
}

extension PaymentEvent {
    public var source: String {
        return funder ?? from ?? source_account
    }

    public var destination: String {
        return account ?? to ?? ""
    }

    public var amount: Decimal {
        return Decimal(string: starting_balance ?? amountString ?? "0.0") ?? Decimal(0)
    }

    public var asset: Asset {
        if type_i == OperationType.CREATE_ACCOUNT || asset_type == "native" {
            return .ASSET_TYPE_NATIVE
        }

        if
            let asset_code = asset_code,
            let asset_issuer = asset_issuer,
            let issuer = StellarKey(asset_issuer)
        {
            return Asset(assetCode: asset_code, issuer: issuer)!
        }

        fatalError("Could not determine asset from payment: \(self)")
    }
}

//MARK: -

public final class EventWatcher<EventType> where EventType: Decodable {
    public var lastEventId: String? { return eventSource.lastEventId }

    private let eventSource: StellarEventSource
    private let emitter: Observer<EventType>

    init(eventSource: StellarEventSource) {
        self.eventSource = eventSource

        self.emitter = eventSource.emitter.compactMap({ event -> EventType? in
            guard let jsonData = event.data?.data(using: .utf8) else {
                return nil
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.stellar)

            return try? decoder.decode(EventType.self, from: jsonData)
        })
    }

    deinit {
        eventSource.close()
        emitter.unlink()
    }

    public func on(queue: DispatchQueue? = nil,
                   next: @escaping (EventType) -> Void) -> Observer<EventType> {
        return emitter.on(queue: queue, next: next)
    }
}
