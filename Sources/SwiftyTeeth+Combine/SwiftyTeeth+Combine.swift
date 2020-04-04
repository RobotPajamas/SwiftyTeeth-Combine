import Combine
import CoreBluetooth
import Foundation
import SwiftyTeeth

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension SwiftyTeeth {
    func statePublisher() -> AnyPublisher<BluetoothState, Never> {
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
    
    func scan(for timeout: TimeInterval = 10) -> AnyPublisher<[Device], Never> {
        return Future { (promise) in
            self.scan(for: timeout) { (devices) in
                promise(.success(devices))
            }
        }.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension Device {
    func connect() -> AnyPublisher<Bool, Never> {
        let subject = CurrentValueSubject<Bool, Never>(self.isConnected)
        self.connect { (isConnected) in
            subject.send(isConnected)
        }
        return subject.eraseToAnyPublisher()
    }
    
    func discoverServices(with uuids: [CBUUID]? = nil) -> AnyPublisher<[CBService], Never> {
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

    func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService) -> AnyPublisher<DiscoveredCharacteristic, Never> {
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
    
    func read(from characteristic: String, in service: String) -> AnyPublisher<Data, Never> {
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
    func write(data: Data, to characteristic: String, in service: String) -> AnyPublisher<Void, Never> {
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
    
    func subscribe(to characteristic: String, in service: String) -> AnyPublisher<Data, Never> {
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
