//
// HorizonRequest.swift
// StellarKit
//
// Created by Kin Foundation.
// Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation
import KinUtil

class HorizonRequest: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    fileprivate class RequestState {
        var data: Data
        var completion: (Data?, Error?) -> ()

        init(data: Data, completion: @escaping (Data?, Error?) -> ()) {
            self.data = data
            self.completion = completion
        }
    }

    private var session: URLSession
    fileprivate var tasks = [URLSessionTask: RequestState]()

    override init() {
        session = URLSession()

        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 10_000

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private struct E: Error { let horizonError: Responses.RequestFailure }

    func get<T: Decodable>(url: URL) -> Promise<T> {
        let p = Promise<T>()

        let task = session.dataTask(with: url)

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

        tasks[task] = RequestState(data: Data(), completion: completion)

        task.resume()

        return p
    }

    func post(request: URLRequest) -> Promise<Data> {
        let p = Promise<Data>()

        let task = session.dataTask(with: request)

        let completion: (Data?, Error?) -> () = { data, error in
            if let error = error {
                p.signal(error)
            }

            if let data = data {
                p.signal(data)
            }
        }

        tasks[task] = RequestState(data: Data(), completion: completion)

        task.resume()

        return p
    }
}

extension HorizonRequest {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let state = tasks[task] {
            state.completion(state.data, error)
            tasks[task] = nil
        }

        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tasks[dataTask]?.data.append(data)
    }
}

extension EP.AccountEndpoint {
    public func get(from base: URL, using: HorizonRequest? = nil) -> Promise<Responses.AccountDetails> {
        return (using ?? HorizonRequest()).get(url: url(with: base))
    }
}

extension EP.LedgersEndpoint {
    public func get(from base: URL, using: HorizonRequest? = nil) -> Promise<Responses.Ledgers> {
        return (using ?? HorizonRequest()).get(url: url(with: base))
    }
}

extension EP.LedgerEndpoint {
    public func get(from base: URL, using: HorizonRequest? = nil) -> Promise<Responses.Ledger> {
        return (using ?? HorizonRequest()).get(url: url(with: base))
    }
}

extension EP.TransactionsEndpoint {
    public func get(from base: URL, using: HorizonRequest? = nil) -> Promise<Responses.Transactions> {
        return (using ?? HorizonRequest()).get(url: url(with: base))
    }
}

extension EP.TransactionEndpoint {
    public func get(from base: URL, using: HorizonRequest? = nil) -> Promise<Responses.Transaction> {
        return (using ?? HorizonRequest()).get(url: url(with: base))
    }
}
