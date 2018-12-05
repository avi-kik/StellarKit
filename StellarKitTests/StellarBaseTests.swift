//
//  StellarBaseTests.swift
//  StellarKitTests
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import StellarKit
import KinUtil
import Sodium

struct MockStellarAccount: Account {
    var publicKey: String? {
        return KeyUtils.base32(publicKey: keyPair.publicKey)
    }
    
    let keyPair: Sign.KeyPair
    
    init(seedStr: String) {
        keyPair = TestKeyUtils.keyPair(from: seedStr)!
        
        let secretKey = keyPair.secretKey
        
        sign = { message in
            return try TestKeyUtils.sign(message: message,
                                         signingKey: secretKey)
        }
    }
    
    var sign: ((Data) throws -> [UInt8])?
    
    init() {
        self.init(seedStr: KeyUtils.base32(seed: TestKeyUtils.seed()!))
    }
}

class StellarBaseTests: XCTestCase {
    var endpoint: String { fatalError("override me") }
    var networkId: NetworkId { fatalError("override me") }
    
    let asset = Asset(assetCode: "TEST_ASSET",
                      issuer: "GBSJ7KFU2NXACVHVN2VWQIXIV5FWH6A7OIDDTEUYTCJYGY3FJMYIDTU7")!
    var node: Stellar.Node!
    
    var account: Account!
    var account2: Account!
    var issuer: Account!
    var funder: Account!

    override func setUp() {
        super.setUp()

        node = Stellar.Node(baseURL: URL(string: endpoint)!, networkId: networkId)

        account = MockStellarAccount()
        account2 = MockStellarAccount()
        issuer = MockStellarAccount(seedStr: "SAXSDD5YEU6GMTJ5IHA6K35VZHXFVPV6IHMWYAQPSEKJRNC5LGMUQX35")
        funder = MockStellarAccount(seedStr: "SDBDJVXHPVQGDXYHEVOBBV4XZUDD7IQTXM5XHZRLXRJVY5YMH4YUCNZC")
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func test_op_sig() {
        let e = expectation(description: "")

        let a1 = MockStellarAccount(seedStr: "SBE2LMR4Y3EBN7EUFSEYL4X7P45HXD27LMQLJAJKLOVZ4BRA5QY6KVAL")
        let a2 = MockStellarAccount(seedStr: "SBYQ56GKLATD6ZCPSH5MUFSIBJQOS2RV7TD7CFLTFK2C5IODTARIKTBZ")

        let x = TxBuilder(source: a1, node: node)
            .add(operation: StellarKit.Operation.payment(destination: a1.publicKey!,
                                                         amount: 1,
                                                         asset: .ASSET_TYPE_NATIVE,
                                                         source: a2))
            .signOperation(at: 0, with: a2)

        x
            .post()
            .then { _ in e.fulfill() }
            .error ({
                if let e = $0 as? Responses.RequestFailure, let r = e.transactionResult {
                    print(r)
                }
                else {
                    print($0)
                }
            })

        wait(for: [e], timeout: 10.0)
    }

    func test_network_parameters() {
        let e = expectation(description: "")

        Stellar.networkConfiguration(node: node)
            .then ({ params in
                XCTAssertGreaterThan(params.baseFee, 0)
            })
            .error({ error in
                XCTAssertFalse(true, "\(error)")
            })
            .finally {
                e.fulfill()
        }

        wait(for: [e], timeout: 120.0)
    }
}
