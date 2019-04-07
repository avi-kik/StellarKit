//
// XDRTests.swift
// StellarKitTests
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
import StellarKit
import KinUtil

class XDRTests: XCTestCase {

    func test_moo() {
        print("SCEGOAM5GBKZVXGYKUI2MKVU5UVLY4VY3NDVSXONH77K75AXPAS2LUKH" as StellarKey)
        print(("SCEGOAM5GBKZVXGYKUI2MKVU5UVLY4VY3NDVSXONH77K75AXPAS2LUKH" as StellarKey).type)
        print(StellarKey("SCEGOAM5GBKZVXGYKUI2MKVU5UVLY4VY3NDVSXONH77K75AXPAS2LUKH")!)
        print(StellarKey(Array(repeating: 7, count: 32)))
        print(StellarKey(Array(repeating: 7, count: 32), type: .ed25519SecretSeed))
    }

    func test_bool() {
        let a: Bool = true
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(Bool.self))
    }

    func test_uint8() {
        let a: UInt8 = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(UInt8.self))
    }

    func test_int32() {
        let a: Int32 = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(Int32.self))
    }

    func test_uint32() {
        let a: UInt32 = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(UInt32.self))
    }

    func test_int64() {
        let a: Int64 = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(Int64.self))
    }

    func test_uint64() {
        let a: UInt64 = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(UInt64.self))
    }

    func test_array() {
        let a: [UInt8] = [123]
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode([UInt8].self))
    }

    func test_string_padded() {
        let a = "a"
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(String.self))
    }

    func test_string_unpadded() {
        let a = "abcd"
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(String.self))
    }

    func test_optional_not_nil() {
        let a: UInt8? = 123
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder.decode(UInt8?.self, data: x))
    }

    func test_optional_nil() {
        let a: UInt8? = nil
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder.decode(UInt8?.self, data: x))
    }

    func test_data() {
        let a: Data = Data(bytes: [123])
        let x = try! XDREncoder.encode(a)
        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(Data.self))
    }

    func test_optional_data() {
        let a: Data? = Data(bytes: [123])
        let x = try! XDREncoder.encode(a)

        try! XCTAssertEqual(a, XDRDecoder(data: x).decode(Data?.self))
    }

    func test_struct() {
        struct S: XDRCodable, XDREncodableStruct {
            let a: String
            let b: Int32

            init(from decoder: XDRDecoder) throws {
                a = try decoder.decode(String.self)
                b = try decoder.decode(Int32.self)
            }

            init(a: String, b: Int32) {
                self.a = a
                self.b = b
            }
        }

        let s = S(a: "a", b: 123)
        let s2 = try! XDRDecoder(data: XDREncoder.encode(s)).decode(S.self)

        XCTAssertEqual(s.b, s2.b)
        XCTAssertEqual(s.a, s2.a)
    }

}
