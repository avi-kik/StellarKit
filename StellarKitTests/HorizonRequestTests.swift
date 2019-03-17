//
// HorizonRequests.swift
// StellarKitTests
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import StellarKit

class HorizonRequestsTests: XCTestCase {
    let account = "GBDYQPNVH7DGKD6ZNBTZY5BZNO2GRHAY7KO3U33UZRBXJDVLBF2PCF6M"
    let txId1 = "79f0cdf85b407b6dd4f342a37a18c6617880192cbeb0c67b5a449bc50df9d52c"
    let txId2 = "aea5d5ef484e729836f28fd090e3600b5e83f0344e8dc053015cd52dfb3a7c45"

    let base = URL(string: "http://localhost:8000")!

    func test_accounts_request() {
        let e = expectation(description: "")

        Endpoint.account(account).get(from: base)
            .then({
                XCTAssert($0.id == self.account)
            })
            .error { print($0); XCTFail() }
            .finally { e.fulfill() }

        wait(for: [e], timeout: 3)
    }

    func test_accounts_transactions_request() {
        let e = expectation(description: "")

        Endpoint.account(account).transactions().get(from: base)
            .then({ (response: Responses.Transactions) in
                XCTAssert(response.transactions.filter { $0.id == self.txId1 }.count == 1)
            })
            .error { print($0); XCTFail() }
            .finally { e.fulfill() }

        wait(for: [e], timeout: 3)
    }

    func test_simultaneous_requests() {
        let e1 = expectation(description: "")
        let e2 = expectation(description: "")

        let requestor = Horizon()

        requestor.get(url: Endpoint.transaction(txId1).url(with: base))
            .then({ (response: Responses.Transaction) in
                XCTAssert(response.id == self.txId1)
            })
            .error { print($0); XCTFail() }
            .finally { e1.fulfill() }

        requestor.get(url: Endpoint.account(account).transactions().url(with: base))
            .then({ (response: Responses.Transactions) in
                XCTAssert(response.transactions.filter { $0.id == self.txId2 }.count == 1)
            })
            .error { print($0); XCTFail() }
            .finally { e2.fulfill() }

        wait(for: [e1, e2], timeout: 3)
    }
}
