//
//  StellarOps.swift
//  StellarKit
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

private func sourceKey(from source: Account?) -> PublicKey? {
    guard let source = source  else { return nil }

    return PublicKey(WD32(source.publicKey.key))
}

extension Operation {
    public static func createAccount(destination: StellarKey,
                                     balance: Int64,
                                     source: Account? = nil) -> Operation {
        let destPK = PublicKey(destination)

        return Operation(sourceAccount: sourceKey(from: source),
                         body: Operation.Body.CREATE_ACCOUNT(CreateAccountOp(destination: destPK,
                                                                             balance: balance)))
    }
    
    public static func payment(destination: StellarKey,
                               amount: Int64,
                               asset: Asset,
                               source: Account? = nil) -> Operation {
        let destPK = PublicKey(destination)

        return Operation(sourceAccount: sourceKey(from: source),
                         body: Operation.Body.PAYMENT(PaymentOp(destination: destPK,
                                                                asset: asset,
                                                                amount: amount)))

    }

    public static func changeTrust(asset: Asset, source: Account? = nil) -> Operation {
        return Operation(sourceAccount: sourceKey(from: source),
                         body: Operation.Body.CHANGE_TRUST(ChangeTrustOp(asset: asset)))
    }

    public static func manageData(key: String, value: Data?, source: Account? = nil) -> Operation {
        return Operation(sourceAccount: sourceKey(from: source),
                         body: Operation.Body.MANAGE_DATA(ManageDataOp(dataName: key, dataValue: value)))
    }
}
