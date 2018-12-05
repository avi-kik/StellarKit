//
//  StellarResults.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

struct TransactionResultCode {
    static let txSUCCESS: Int32 = 0               // all operations succeeded

    static let txFAILED: Int32 = -1               // one of the operations failed (none were applied)

    static let txTOO_EARLY: Int32 = -2            // ledger closeTime before minTime
    static let txTOO_LATE: Int32 = -3             // ledger closeTime after maxTime
    static let txMISSING_OPERATION: Int32 = -4    // no operation was specified
    static let txBAD_SEQ: Int32 = -5              // sequence number does not match source account

    static let txBAD_AUTH: Int32 = -6             // too few valid signatures / wrong network
    static let txINSUFFICIENT_BALANCE: Int32 = -7 // fee would bring account below reserve
    static let txNO_ACCOUNT: Int32 = -8           // source account not found
    static let txINSUFFICIENT_FEE: Int32 = -9     // fee is too small
    static let txBAD_AUTH_EXTRA: Int32 = -10      // unused signatures attached to transaction
    static let txINTERNAL_ERROR: Int32 = -11      // an unknown error occured
}

public struct TransactionResult: XDRCodable, XDREncodableStruct {
    public let feeCharged: Int64
    public let result: Result
    public let reserved: Int32 = 0

    public enum Result: XDRCodable {
        case txSUCCESS([OperationResult])
        case txFAILED([OperationResult])
        case txTOO_EARLY
        case txTOO_LATE
        case txMISSING_OPERATION
        case txBAD_SEQ
        case txBAD_AUTH
        case txINSUFFICIENT_BALANCE
        case txNO_ACCOUNT
        case txINSUFFICIENT_FEE
        case txBAD_AUTH_EXTRA
        case txINTERNAL_ERROR

        public init(from decoder: XDRDecoder) throws {
            let discriminant = try decoder.decode(Int32.self)

            switch discriminant {
            case TransactionResultCode.txSUCCESS:
                self = .txSUCCESS(try decoder.decodeArray(OperationResult.self))
            case TransactionResultCode.txFAILED:
                self = .txFAILED(try decoder.decodeArray(OperationResult.self))
            case TransactionResultCode.txTOO_EARLY:
                self = .txTOO_EARLY
            case TransactionResultCode.txTOO_LATE:
                self = .txTOO_LATE
            case TransactionResultCode.txMISSING_OPERATION:
                self = .txMISSING_OPERATION
            case TransactionResultCode.txBAD_SEQ:
                self = .txBAD_SEQ
            case TransactionResultCode.txBAD_AUTH:
                self = .txBAD_AUTH
            case TransactionResultCode.txINSUFFICIENT_BALANCE:
                self = .txINSUFFICIENT_BALANCE
            case TransactionResultCode.txNO_ACCOUNT:
                self = .txNO_ACCOUNT
            case TransactionResultCode.txINSUFFICIENT_FEE:
                self = .txINSUFFICIENT_FEE
            case TransactionResultCode.txBAD_AUTH_EXTRA:
                self = .txBAD_AUTH_EXTRA
            case TransactionResultCode.txINTERNAL_ERROR:
                self = .txINTERNAL_ERROR
            default:
                self = .txINTERNAL_ERROR
            }
        }

        private func discriminant() -> Int32 {
            switch self {
            case .txSUCCESS: return TransactionResultCode.txSUCCESS
            case .txFAILED: return TransactionResultCode.txFAILED
            case .txTOO_EARLY: return TransactionResultCode.txTOO_EARLY
            case .txTOO_LATE: return TransactionResultCode.txTOO_LATE
            case .txMISSING_OPERATION: return TransactionResultCode.txMISSING_OPERATION
            case .txBAD_SEQ: return TransactionResultCode.txBAD_SEQ
            case .txBAD_AUTH: return TransactionResultCode.txBAD_AUTH
            case .txINSUFFICIENT_BALANCE: return TransactionResultCode.txINSUFFICIENT_BALANCE
            case .txNO_ACCOUNT: return TransactionResultCode.txNO_ACCOUNT
            case .txINSUFFICIENT_FEE: return TransactionResultCode.txINSUFFICIENT_FEE
            case .txBAD_AUTH_EXTRA: return TransactionResultCode.txBAD_AUTH_EXTRA
            case .txINTERNAL_ERROR: return TransactionResultCode.txINTERNAL_ERROR
            }
        }

        public func encode(to encoder: XDREncoder) throws {
            try encoder.encode(discriminant())

            switch self {
            case .txSUCCESS(let ops): try encoder.encode(ops)
            case .txFAILED(let ops): try encoder.encode(ops)
            default:
                break
            }
        }
    }

    public init(from decoder: XDRDecoder) throws {
        feeCharged = try decoder.decode(Int64.self)
        result = try decoder.decode(Result.self)
        _ = try decoder.decode(Int32.self)
    }

    init(feeCharged: Int64, result: Result) {
        self.feeCharged = feeCharged
        self.result = result
    }
}

struct OperationResultCode {
    static let opINNER: Int32 = 0       // inner object result is valid

    static let opBAD_AUTH: Int32 = -1   // too few valid signatures / wrong network
    static let opNO_ACCOUNT: Int32 = -2 // source account was not found
}

public enum OperationResult: XDRCodable {
    case opINNER (Tr)
    case opBAD_AUTH
    case opNO_ACCOUNT

    // Add cases as necessary.
    public enum Tr: XDRCodable {
        case CREATE_ACCOUNT(CreateAccountResult)
        case CHANGE_TRUST(ChangeTrustResult)
        case PAYMENT(PaymentResult)
        case MANAGE_DATA(ManageDataResult)
        case unknown

        public init(from decoder: XDRDecoder) throws {
            let discriminant = try decoder.decode(Int32.self)

            switch discriminant {
            case OperationType.PAYMENT:
                self = .PAYMENT(try decoder.decode(PaymentResult.self))
            case OperationType.CREATE_ACCOUNT:
                self = .CREATE_ACCOUNT(try decoder.decode(CreateAccountResult.self))
            case OperationType.CHANGE_TRUST:
                self = .CHANGE_TRUST(try decoder.decode(ChangeTrustResult.self))
            default:
                self = .unknown
            }
        }

        private func discriminant() -> Int32 {
            switch self {
            case .CREATE_ACCOUNT: return OperationType.CREATE_ACCOUNT
            case .PAYMENT: return OperationType.PAYMENT
            default:
                return -1
            }
        }

        public func encode(to encoder: XDREncoder) throws {
            try encoder.encode(discriminant())

            switch self {
            case .CREATE_ACCOUNT(let result): try encoder.encode(result)
            case .PAYMENT(let result): try encoder.encode(result)
            default:
                break
            }
        }
    }

    public init(from decoder: XDRDecoder) throws {
        let discriminant = try decoder.decode(Int32.self)

        switch discriminant {
        case OperationResultCode.opINNER:
            self = .opINNER(try decoder.decode(Tr.self))
        case OperationResultCode.opBAD_AUTH:
            self = .opBAD_AUTH
        case OperationResultCode.opNO_ACCOUNT:
            self = .opNO_ACCOUNT
        default:
            self = .opNO_ACCOUNT
        }
    }

    private func discriminant() -> Int32 {
        switch self {
        case .opINNER: return OperationResultCode.opINNER
        case .opBAD_AUTH: return OperationResultCode.opBAD_AUTH
        case .opNO_ACCOUNT: return OperationResultCode.opNO_ACCOUNT
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())

        switch self {
        case .opINNER(let tr): try encoder.encode(tr)
        case .opBAD_AUTH: break
        case .opNO_ACCOUNT: break
        }
    }
}

public struct CreateAccountResultCode {
    public static let CREATE_ACCOUNT_SUCCESS: Int32 = 0        // account was created

    public static let CREATE_ACCOUNT_MALFORMED: Int32 = -1     // invalid destination
    public static let CREATE_ACCOUNT_UNDERFUNDED: Int32 = -2   // not enough funds in source account
    public static let CREATE_ACCOUNT_LOW_RESERVE: Int32 = -3   // would create an account below the min reserve
    public static let CREATE_ACCOUNT_ALREADY_EXIST: Int32 = -4 // account already exists
}

public enum CreateAccountResult: XDRCodable {
    case success
    case failure (Int32)

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return CreateAccountResultCode.CREATE_ACCOUNT_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }
}

struct ChangeTrustResultCode {
    static let CHANGE_TRUST_SUCCESS: Int32 = 0

    static let CHANGE_TRUST_MALFORMED: Int32 = -1           // bad input
    static let CHANGE_TRUST_NO_ISSUER: Int32 = -2           // could not find issuer
    static let CHANGE_TRUST_INVALID_LIMIT: Int32 = -3       // cannot drop limit below balance
    static let CHANGE_TRUST_LOW_RESERVE: Int32 = -4         // not enough funds to create a new trust line,
    static let CHANGE_TRUST_SELF_NOT_ALLOWED: Int32 = -5    // trusting self is not allowed
};

public enum ChangeTrustResult: XDRCodable {
    case success
    case failure (Int32)

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return ChangeTrustResultCode.CHANGE_TRUST_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }
}

struct PaymentResultCode {
    // codes considered as "success" for the operation
    static let PAYMENT_SUCCESS: Int32 = 0 // payment successfuly completed

    // codes considered as "failure" for the operation
    static let PAYMENT_MALFORMED: Int32 = -1          // bad input
    static let PAYMENT_UNDERFUNDED: Int32 = -2        // not enough funds in source account
    static let PAYMENT_SRC_NO_TRUST: Int32 = -3       // no trust line on source account
    static let PAYMENT_SRC_NOT_AUTHORIZED: Int32 = -4 // source not authorized to transfer
    static let PAYMENT_NO_DESTINATION: Int32 = -5     // destination account does not exist
    static let PAYMENT_NO_TRUST: Int32 = -6           // destination missing a trust line for asset
    static let PAYMENT_NOT_AUTHORIZED: Int32 = -7     // destination not authorized to hold asset
    static let PAYMENT_LINE_FULL: Int32 = -8          // destination would go above their limit
    static let PAYMENT_NO_ISSUER: Int32 = -9          // missing issuer on asset
}

public enum PaymentResult: XDRCodable {
    case success
    case failure (Int32)

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return PaymentResultCode.PAYMENT_SUCCESS
        case .failure (let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }
}

struct ManageDataResultCode {
    // codes considered as "success" for the operation
    static let MANAGE_DATA_SUCCESS: Int32 = 0

    // codes considered as "failure" for the operation
    static let MANAGE_DATA_NOT_SUPPORTED_YET: Int32 = -1  // The network hasn't moved to this protocol change yet
    static let MANAGE_DATA_NAME_NOT_FOUND: Int32 = -2     // Trying to remove a Data Entry that isn't there
    static let MANAGE_DATA_LOW_RESERVE: Int32 = -3        // not enough funds to create a new Data Entry
    static let MANAGE_DATA_INVALID_NAME: Int32 = -4       // Name not a valid string
}

public enum ManageDataResult: XDRCodable {
    case success
    case failure(Int32)

    private func discriminant() -> Int32 {
        switch self {
        case .success:
            return ManageDataResultCode.MANAGE_DATA_SUCCESS
        case .failure(let code):
            return code
        }
    }

    public func encode(to encoder: XDREncoder) throws {
        try encoder.encode(discriminant())
    }

    public init(from decoder: XDRDecoder) throws {
        let value = try decoder.decode(Int32.self)

        self = value == 0 ? .success : .failure(value)
    }
}
