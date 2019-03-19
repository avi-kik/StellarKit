//
// Horizon.swift
// StellarKit
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

fileprivate class RequestState {
    var data = Data()
    var completion: (Data?, Error?) -> ()

    init(completion: @escaping (Data?, Error?) -> ()) {
        self.completion = completion
    }
}

public class Horizon {
    let wrapper = SessionWrapper()

    deinit {
        wrapper.session.finishTasksAndInvalidate()
    }

    private struct E: Error { let horizonError: Responses.RequestFailure }

    public func get<T: Decodable>(url: URL) -> Promise<T> {
        let p = Promise<T>()

        let task = wrapper.session.dataTask(with: url)

        let completion: (Data?, Error?) -> () = { data, error in
            if let error = error {
                p.signal(error)
            }

            if let e = try? JSONDecoder().decode(Responses.RequestFailure.self, from: data!) {
                p.signal(e)
            }
            else {
                do {
                    p.signal(try JSONDecoder().decode(T.self, from: data!))
                }
                catch {
                    p.signal(error)
                }
            }
        }

        wrapper.tasks[task] = RequestState(completion: completion)

        task.resume()

        return p
    }

    public func post(request: URLRequest) -> Promise<Data> {
        let p = Promise<Data>()

        let task = wrapper.session.dataTask(with: request)

        let completion: (Data?, Error?) -> () = { data, error in
            if let error = error {
                p.signal(error)
            }

            if let data = data {
                p.signal(data)
            }
        }

        wrapper.tasks[task] = RequestState(completion: completion)

        task.resume()

        return p
    }
}

class SessionWrapper: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    fileprivate var session: URLSession
    fileprivate var tasks = [URLSessionTask: RequestState]()

    var shouldInvalidateAfterCompletion = true

    override init() {
        session = URLSession(configuration: URLSessionConfiguration.default)

        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 10_000

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
}

extension SessionWrapper {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let state = tasks[task] {
            state.completion(state.data, error)
            tasks[task] = nil
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tasks[dataTask]?.data.append(data)
    }
}

extension EP.AccountEndpoint {
    public func get(from base: URL, using: Horizon? = nil) -> Promise<Responses.AccountDetails> {
        return (using ?? Horizon()).get(url: url(with: base))
    }
}

extension EP.LedgersEndpoint {
    public func get(from base: URL, using: Horizon? = nil) -> Promise<Responses.Ledgers> {
        return (using ?? Horizon()).get(url: url(with: base))
    }
}

extension EP.LedgerEndpoint {
    public func get(from base: URL, using: Horizon? = nil) -> Promise<Responses.Ledger> {
        return (using ?? Horizon()).get(url: url(with: base))
    }
}

extension EP.TransactionsEndpoint {
    public func get(from base: URL, using: Horizon? = nil) -> Promise<Responses.Transactions> {
        return (using ?? Horizon()).get(url: url(with: base))
    }
}

extension EP.TransactionEndpoint {
    public func get(from base: URL, using: Horizon? = nil) -> Promise<Responses.Transaction> {
        return (using ?? Horizon()).get(url: url(with: base))
    }
}
