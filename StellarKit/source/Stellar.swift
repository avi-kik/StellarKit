//
//  Stellar.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

public struct NetworkId {
    private static let stellarTestId = "Test SDF Network ; September 2015"
    private static let stellarMainId = "Public Global Stellar Network ; September 2015"
    private static let kinTestId = "Kin Testnet ; December 2018"
    private static let kinMainId = "Kin Mainnet ; December 2018"

    public let identifier: String

    public init(_ identifier: String) { self.identifier = identifier }
}
extension NetworkId {
    public static var stellarMain: NetworkId { return NetworkId(stellarMainId) }
    public static var stellarTest: NetworkId { return NetworkId(stellarTestId) }
    public static var kinMain: NetworkId { return NetworkId(kinMainId) }
    public static var kinTest: NetworkId { return NetworkId(kinTestId) }
}

extension NetworkId: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: StringLiteralType) {
        self.identifier = stringLiteral
    }
}

extension NetworkId: CustomStringConvertible {
    public var description: String { return identifier }
}

public struct NetworkConfiguration {
    let baseFee: UInt32
    let baseReserve: UInt32
    let maxTxSetSize: Int

    fileprivate init(_ ledgers: Responses.Ledgers) {
        baseFee = ledgers.ledgers[0].baseFee
        baseReserve = ledgers.ledgers[0].baseReserve
        maxTxSetSize = ledgers.ledgers[0].max_tx_set_size
    }
}

public struct Node {
    public let baseURL: URL
    public let networkId: NetworkId

    public init(baseURL: URL, networkId: NetworkId) {
        self.baseURL = baseURL
        self.networkId = networkId
    }
}

extension Node {
    /**
     Obtain a `TxBuilder` configured with `self` as the node.

     - parameter account: The source account for the built transaction.

     - Returns: A preconfigured `TxBuilder`.
     */
    public func txBuilder(account: Account) -> TxBuilder {
        return TxBuilder(source: account, node: self)
    }

    /**
     Obtain the network configuration.  Network configuration conists of parameters
     obtained from the last ledger ingested by the node.

     - Returns: A promise which yields a `NetworkConfiguration` object.
     */
    public func networkConfiguration() -> Promise<NetworkConfiguration> {
        return Endpoint.ledgers().order(.desc).limit(1).get(from: baseURL)
            .then({ (response: Responses.Ledgers) -> Promise<NetworkConfiguration> in
                return Promise(NetworkConfiguration(response))
            })
    }

    /**
     Observe transactions on the given node.

     - parameter lastEventId: If non-`nil`, only transactions with a later event Id will be observed.
     A value of **"now"** will only observe transactions completed after observation begins.

     - Returns: An instance of `TxWatch`, which contains an `Observable` which emits `TxInfo` objects.
     */
    public func txWatch(lastEventId: String?) -> EventWatcher<TxEvent> {
        let url = Endpoint.transactions().cursor(lastEventId).url(with: baseURL)

        return EventWatcher(eventSource: StellarEventSource(url: url))
    }

    /**
     Observe payments on the given node.

     - parameter lastEventId: If non-`nil`, only payments with a later event Id will be observed.
     A value of **"now"** will only observe payments completed after observation begins.

     - Returns: An instance of `EventWatcher`, which contains an `Observable` which emits `PaymentEvent` objects.
     */
    public func paymentWatch(lastEventId: String?) -> EventWatcher<PaymentEvent> {
        let url = Endpoint.payments().cursor(lastEventId).url(with: baseURL)

        return EventWatcher(eventSource: StellarEventSource(url: url))
    }

    /**
     Submit a transaction to the node.

     - parameter envelope: The transaction envelope to post.  Envelopes can be obtained
     from a `TxBuilder` instance.
     - parameter using: An instance of Horizon with which to post.  Providing
     an instance allows for a single `URLSession` to be used.

     - Returns: A promise which yields the result of the POST operation.
     */
    public func post(envelope: TransactionEnvelope,
                     using horizon: Horizon? = nil) -> Promise<Responses.TransactionSuccess> {
        let envelopeData: Data
        do {
            envelopeData = try Data(XDREncoder.encode(envelope))
        }
        catch {
            return Promise(error)
        }

        guard let urlEncodedEnvelope = envelopeData.base64EncodedString().urlEncoded else {
            return Promise(StellarError.urlEncodingFailed)
        }

        guard let httpBody = ("tx=" + urlEncodedEnvelope).data(using: .utf8) else {
            return Promise(StellarError.dataEncodingFailed)
        }

        var request = URLRequest(url: Endpoint.transactions().url(with: baseURL))
        request.httpMethod = "POST"
        request.httpBody = httpBody

        return (horizon ?? Horizon()).post(request: request)
            .then {
                return try JSONDecoder()
                    .decode(Responses.TransactionSuccess.self, from: $0)
        }
    }
}

public protocol Account {
    var publicKey: StellarKey { get }
    
    func sign<S: Sequence>(_ message: S) throws -> [UInt8] where S.Element == UInt8

    init(stellarKey: StellarKey)
}

extension Account {
    public func details(node: Node) -> Promise<Responses.AccountDetails> {
        return Endpoint.account(String(publicKey)).get(from: node.baseURL)
    }

    public func sequence(seqNum: UInt64 = 0, node: Node) -> Promise<UInt64> {
        if seqNum > 0 {
            return Promise().signal(seqNum)
        }

        return details(node: node)
            .then { return Promise<UInt64>().signal($0.seqNum + 1) }
    }

    public func balance(asset: Asset = .ASSET_TYPE_NATIVE, node: Node) -> Promise<Decimal> {
        return details(node: node)
            .then({ details -> Decimal in
                if let balance = details.balances.filter({ $0.asset == asset }).first {
                    return balance.balanceNum
                }

                throw StellarError.missingBalance
            })
    }

    /**
     Obtain a `TxBuilder` configured with `self` as the source account.

     - parameter node: The node to which the built transaction will be sent.

     - Returns: A preconfigured `TxBuilder`.
     */
    public func txBuilder(node: Node) -> TxBuilder {
        return TxBuilder(source: self, node: node)
    }

    /**
     Observe transactions for the account on the given node.

     - parameter lastEventId: If non-`nil`, only transactions with a later event Id will be observed.
     A value of **"now"** will only observe transactions completed after observation begins.
     - parameter node: An object describing the network endpoint.

     - Returns: An instance of `EventWatcher`, which contains an `Observable` which emits `TxEvent` objects.
     */
    public func txWatch(lastEventId: String?, node: Node) -> EventWatcher<TxEvent> {
        let url = Endpoint.account(String(publicKey))
            .transactions()
            .cursor(lastEventId)
            .url(with: node.baseURL)

        return EventWatcher(eventSource: StellarEventSource(url: url))
    }

    /**
     Observe payments for the account on the given node.

     - parameter lastEventId: If non-`nil`, only payments with a later event Id will be observed.
     A value of **"now"** will only observe payments completed after observation begins.
     - parameter node: An object describing the network endpoint.

     - Returns: An instance of `EventWatcher`, which contains an `Observable` which emits `PaymentEvent` objects.
     */
    public func paymentWatch(lastEventId: String?, node: Node) -> EventWatcher<PaymentEvent> {
        let url = Endpoint.account(String(publicKey))
            .payments()
            .cursor(lastEventId)
            .url(with: node.baseURL)

        return EventWatcher(eventSource: StellarEventSource(url: url))
    }
}

extension Transaction {
    public func signature(using account: Account, for node: Node) throws -> DecoratedSignature {
        let sig = try account.sign(self.hash(networkId: node.networkId.identifier))

        let hint = WrappedData4(account.publicKey.key.suffix(4))

        return DecoratedSignature(hint: hint, signature: sig)
    }
}

extension TransactionEnvelope {
    public func post(to node: Node,
                     using horizon: Horizon? = nil) -> Promise<Responses.TransactionSuccess> {
        return node.post(envelope: self, using: horizon)
    }
}

extension Promise where Value == TransactionEnvelope {
    public func post(to node: Node,
                     using horizon: Horizon? = nil) -> Promise<Responses.TransactionSuccess> {
        return self.then({
            return node.post(envelope: $0, using: horizon)
        })
    }
}
