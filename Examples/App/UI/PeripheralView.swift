//
//  DeviceView.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-27.
//

import Combine
import CoreBluetooth
import SwiftyTeeth
import SwiftUI

final class PeripheralViewModel: ObservableObject {
    let peripheral: Device
    let serviceUuid = UUID(uuidString: "00726f62-6f74-7061-6a61-6d61732e6361")!
    let txUuid = UUID(uuidString: "01726f62-6f74-7061-6a61-6d61732e6361")!
    let rxUuid = UUID(uuidString: "02726f62-6f74-7061-6a61-6d61732e6361")!

    @Published var logMessage = ""
    
    private var cancellables: Set<AnyCancellable> = []
    private var connectCancellable: AnyCancellable?
    
    init(peripheral: Device) {
        self.peripheral = peripheral
    }
    
    private func log(_ text: String) {
        print(text)
        DispatchQueue.main.async {
            self.logMessage.append(text + "\n")
        }
    }
    
    func connect() {
        connectCancellable = peripheral.connect()
            .removeDuplicates()
            .filter { $0 == .connected }
            .flatMap { (isConnected) -> AnyPublisher<[Service], Never> in
                self.log("App: Device is connected? \(isConnected)")
                self.log("App: Starting service discovery...")
                return self.peripheral.discoverServices()
            }
            .flatMap { (services) in
                return services.publisher
            }
            .flatMap(maxPublishers: .max(1)) { (service) -> AnyPublisher<DiscoveredCharacteristic, Never> in
                self.log("App: Discovering characteristics for service: \(service.uuid.uuidString)")
                return self.peripheral.discoverCharacteristics(for: service)
            }
            .flatMap { (discoveredCharacteristic) in
                return discoveredCharacteristic.characteristics.map { (characteristic) -> (Service, Characteristic) in
                    return (discoveredCharacteristic.service, characteristic)
                }.publisher
            }
            .sink { [weak self] (value) in
                self?.log("App: Discovered characteristic: \(value.1.uuid.uuidString) in \(value.0.uuid.uuidString)")
            }
    }
    
    func disconnect() {
        connectCancellable?.cancel()
        connectCancellable = nil
    }
    
    func subscribe() {
        peripheral.subscribe(to: rxUuid, in: serviceUuid)
            .sink { [weak self] (value) in
                self?.log("Subscribed value: \([UInt8](value))")
            }.store(in: &cancellables)
    }
    
    func read() {
        peripheral.read(from: rxUuid, in: serviceUuid)
            .sink { [weak self] (value) in
                self?.log("Read value: \([UInt8](value))")
            }.store(in: &cancellables)
    }
    
    func write() {
        let command = Data([0x01])
        peripheral.write(data: command, to: txUuid, in: serviceUuid)
            .sink { [weak self] (value) in
                self?.log("Write with response successful? \(value)")
            }.store(in: &cancellables)
    }
}

struct PeripheralView: View {
    @ObservedObject var vm: PeripheralViewModel
    let peripheral: Device
    
    init(peripheral: Device) {
        self.peripheral = peripheral
        self.vm = PeripheralViewModel(peripheral: peripheral)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Subscribe") {
                    self.vm.subscribe()
                }
                Spacer()
                Button("Read") {
                    self.vm.read()
                }
                Spacer()
                Button("Write") {
                    self.vm.write()
                }
                Spacer()
            }
            TextView(text: $vm.logMessage, autoscroll: true)
        }.onAppear {
            self.vm.connect()
        }.onDisappear {
            self.vm.disconnect()
        }.navigationBarTitle("Peripheral", displayMode: .inline)
    }
}
