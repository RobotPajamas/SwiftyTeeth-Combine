import Combine
import Foundation
import SwiftyTeeth

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension SwiftyTeeth {
    func state() -> AnyPublisher<BluetoothState, Never> {
        let publisher = CurrentValueSubject<BluetoothState, Never>(self.state)
        self.stateChangedHandler = { (state) in
            publisher.send(state)
        }
        return publisher.eraseToAnyPublisher()
    }
    
    func scanPublisher() -> AnyPublisher<Device, Never> {
        let subject = PassthroughSubject<Device, Never>()
        self.scan { (device) in
            subject.send(device)
        }
        return subject
            .handleEvents(receiveCompletion: { (_) in
                self.stopScan()
            }, receiveCancel: {
                self.stopScan()
            }).eraseToAnyPublisher()
    }
    
    func scan(for timeout: TimeInterval) -> AnyPublisher<[Device], Never> {
        return Future { (promise) in
            self.scan(for: timeout) { (devices) in
                promise(.success(devices))
            }
        }.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension Device {
    func state() -> AnyPublisher<ConnectionState, Never> {
        let publisher = CurrentValueSubject<ConnectionState, Never>(self.connectionState)
        self.connectionStateChangedHandler = { (state) in
            publisher.send(state)
        }
        return publisher.eraseToAnyPublisher()
    }

    func connect() -> AnyPublisher<ConnectionState, Never> {
        let subject = CurrentValueSubject<ConnectionState, Never>(self.connectionState)
        self.connect { (state) in
            subject.send(state)
        }
        return subject.eraseToAnyPublisher()
    }
    
    func discoverServices(with uuids: [UUID]? = nil) -> AnyPublisher<[Service], Never> {
        return Future { (promise) in
            self.discoverServices(with: uuids) { (result) in
                switch result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    break // TODO
//                    promise(.failure())
                }
            }
        }.eraseToAnyPublisher()
    }

    func discoverCharacteristics(with uuids: [UUID]? = nil, for service: Service) -> AnyPublisher<DiscoveredCharacteristic, Never> {
        return Deferred {
            return Future { (promise) in
                self.discoverCharacteristics(with: uuids, for: service) { (result) in
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        break // TODO
    //                    promise(.failure())
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func read(from characteristic: UUID, in service: UUID) -> AnyPublisher<Data, Never> {
        return Deferred {
            return Future { (promise) in
                self.read(from: characteristic, in: service) { (result) in
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
    //                    promise(.failure())
                        break
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // TODO: Handle write-no-response
    // Should be Single<>?
    func write(data: Data, to characteristic: UUID, in service: UUID) -> AnyPublisher<Void, Never> {
        return Deferred {
            return Future { (promise) in
                self.write(data: data, to: characteristic, in: service) { (result) in
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
    //                    promise(.failure())
                        break
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func subscribe(to characteristic: UUID, in service: UUID) -> AnyPublisher<Data, Never> {
        let subject = PassthroughSubject<Data, Never>()
        self.subscribe(to: characteristic, in: service) { (result) in
            switch result {
            case .success(let value):
                subject.send(value)
            case .failure(let error):
//                observer.onError(error)
                break
            }
        }
        // TODO: Unsubscribe on cancel
        return subject.eraseToAnyPublisher()
    }
}
