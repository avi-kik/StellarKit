# StellarKit

A framework for interacting with the [Stellar](https://www.stellar.org) blockchain network.  StellarKit communicates with Horizon nodes.

## The Fork

This is a fork of the official, now defunct, repo from [Kin Ecosystem](https://github.com/kinecosystem/StellarKit).  This fork aims to be compatible with official Stellar networks, while also supporting the Kin Blockchain.

## Availability

Besides being usable as an Xcode subproject, there is full SPM support.  The CocoaPod will not be maintained.

The framework builds on iOS and macOS, and has been known to build on Linux.

## Compatibility

Source and API compatibility between commits is an anti-goal.  The framework is in a constant state of revision and improvement.  If stability is desired, it is recommended that a fork is created and maintained.

This framework will be migrated to official Swift releases, as included with Xcode updates and upgrades.

## The Cast

- Node
- Account
- TxBuilder

### Node
An instance of `Node` represents a single Horizon-compatible endpoint.  It can be used to query non-account-specific information from the network.

### Account
`Account` is a protocol.  Conforming types represent a public address on the network, and provides a facility for signing transactions.  The API includes methods for querying account-specific information.

### TxBuilder
An instance of `TxBuilder` allows construction of a single transaction.  All aspects of a transaction are configurable with the available API.

## Some notes about XDR

Stellar uses [XDR](https://tools.ietf.org/html/rfc4506), a binary format for data interchange.  StellarKit includes an almost complete [XDR coder and decoder](https://github.com/avi-kik/StellarKit/blob/master/StellarKit/source/XDRCodable.swift), loosely modeled on the native `Codable` protocols.  Data types not used by `Stellar` are not included (primarily floating point types).

StellarKit defines `struct`s and `enum`s for many of Stellar's xdr definitions (contributions welcome!).  Unfortunately, `enum`s are not always ergonomic in Swift, and thus StellarKit adds convenience methods for many such definitions to ease the pain.

## Future Direction

This framework was born out of a need for an iOS SDK for Stellar.  While Kin Ecosystem has moved in a different direction, this framework hopes to maintain compatibility with official Stellar networks.  That said, it is maintained as part of my responsibilities as a Kin Blockchain developer, and is thus missing much functionality provided by Horizon and stellar-core.  Pull requests to add support for missing operations and responses will be welcomed.
