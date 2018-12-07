//
//  StellarIntegrationTests.swift
//  StellarKitTests
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import StellarKit
import KinUtil
import Sodium

struct MockStellarAccount: Account {
    private var _publicKey: String?

    var publicKey: String {
        return _publicKey ?? KeyUtils.base32(publicKey: keyPair!.publicKey)
    }

    var keyPair: Sign.KeyPair?

    func sign(_ message: Data) throws -> [UInt8] {
        return try TestKeyUtils.sign(message: message, signingKey: keyPair!.secretKey)
    }

    init() {
        self.init(seedStr: KeyUtils.base32(seed: TestKeyUtils.seed()!))
    }

    init(publicKey: String) {
        _publicKey = publicKey
    }

    init(seedStr: String) {
        keyPair = TestKeyUtils.keyPair(from: seedStr)
    }
}

class StellarIntegrationTests: XCTestCase {
    var endpoint: String { return "http://localhost:8000" }
    var networkId: NetworkId { return .custom("private testnet") }

    let asset = Asset(assetCode: "TEST_ASSET",
                      issuer: "GBSJ7KFU2NXACVHVN2VWQIXIV5FWH6A7OIDDTEUYTCJYGY3FJMYIDTU7")!
    var node: Node!

    var issuer: Account!
    var funder: Account!

    var found = false

    override func setUp() {
        super.setUp()

        node = Node(baseURL: URL(string: endpoint)!, networkId: networkId)

        issuer = MockStellarAccount(seedStr: "SAXSDD5YEU6GMTJ5IHA6K35VZHXFVPV6IHMWYAQPSEKJRNC5LGMUQX35")
        funder = MockStellarAccount(seedStr: "SDBDJVXHPVQGDXYHEVOBBV4XZUDD7IQTXM5XHZRLXRJVY5YMH4YUCNZC")

        linkBag = LinkBag()

        if !found {
            find_divisor()
            found = true
        }
    }

    override func tearDown() {
        super.tearDown()

        linkBag.clear()
    }

    let initial_balance: Int64 = 10_000 * 100_000
    var divisor: Int64 = 100_000

    func find_divisor() {
        let e = expectation(description: "")

        let a = MockStellarAccount()

        createIfNecessary(a, balance: 1)

        a.balance(node: node)
            .then ({
                var divisor: Decimal = 1

                while $0 * divisor < 1 { divisor *= 10 }

                self.divisor = (divisor as NSDecimalNumber).int64Value

                e.fulfill()
            })

        wait(for: [e], timeout: 20.0)
    }

    func createIfNecessary(_ account: Account, balance: Int64 = 10_000 * 100_000) {
        let e = expectation(description: "createIfNecessary")

        TxBuilder(source: funder, node: node)
            .add(operation: StellarKit.Operation.createAccount(destination: account.publicKey,
                                                               balance: balance))
            .post()
            .then { _ in e.fulfill() }
            .error {
                if ($0 as? Responses.RequestFailure)?.isExistingAccount == true {
                    e.fulfill()
                }
        }

        wait(for: [e], timeout: 15.0)
    }

    func test_network_parameters() {
        let e = expectation(description: "")

        node.networkConfiguration()
            .then { XCTAssertGreaterThan($0.baseFee, 0) }
            .error { print($0); XCTFail() }
            .finally { e.fulfill() }

        wait(for: [e], timeout: 10.0)
    }

    var txWatch: EventWatcher<TxEvent>?
    var paymentWatch: EventWatcher<PaymentEvent>?
    var linkBag = LinkBag()

    func test_node_tx_watch() {
        let e = expectation(description: "")

        var triggered = false

        txWatch = node.txWatch(lastEventId: nil)
        txWatch?.emitter.on(next: { _ in
            if !triggered { e.fulfill() }
            triggered = true
        }).add(to: linkBag)

        wait(for: [e], timeout: 120.0)

        txWatch = nil
    }

    func test_node_tx_watch_cursor_now() {
        let e = expectation(description: "")

        var triggered = false

        txWatch = node.txWatch(lastEventId: "now")
        txWatch?.emitter.on(next: { _ in
            if !triggered { e.fulfill() }
            triggered = true
        }).add(to: linkBag)

        createIfNecessary(MockStellarAccount())

        wait(for: [e], timeout: 120.0)

        txWatch = nil
    }

    func test_node_payment_watch() {
        let e = expectation(description: "")

        var triggered = false

        paymentWatch = node.paymentWatch(lastEventId: nil)
        paymentWatch?.emitter.on(next: { _ in
            if !triggered { e.fulfill() }
            triggered = true
        }).add(to: linkBag)

        wait(for: [e], timeout: 120.0)

        paymentWatch = nil
    }

    func test_node_payment_watch_cursor_now() {
        let e = expectation(description: "")

        var triggered = false

        paymentWatch = node.paymentWatch(lastEventId: "now")
        paymentWatch?.emitter.on(next: { _ in
            if !triggered { e.fulfill() }
            triggered = true
        }).add(to: linkBag)

        createIfNecessary(MockStellarAccount())

        wait(for: [e], timeout: 120.0)

        paymentWatch = nil
    }

    func test_no_balance() {
        let e = expectation(description: "")

        let account = MockStellarAccount()

        account.balance(node: node)
            .error {
                if ($0 as? Responses.RequestFailure)?.isMissingAccount == true {
                    e.fulfill()
                }
        }

        wait(for: [e], timeout: 10.0)
    }

    func test_balance() {
        let e = expectation(description: "")

        let account = MockStellarAccount()

        createIfNecessary(account)

        account.balance(node: node)
            .then {
                XCTAssertEqual($0, Decimal(Double(self.initial_balance) / Double(self.divisor)))
                e.fulfill()
        }

        wait(for: [e], timeout: 15.0)
    }
}
