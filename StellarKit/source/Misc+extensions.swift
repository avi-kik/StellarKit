//
// Misc+extensions.swift
// StellarKit
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

extension DateFormatter {
    static var stellar: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return df
    }()
}

public extension Data {
    var sha256: [UInt8] {
        return SHA256(self.array).digest()
    }
}
