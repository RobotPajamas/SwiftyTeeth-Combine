//
//  ScanningView.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-27.
//

import Combine
import SwiftUI
import SwiftyTeeth

final class ScanningViewModel: ObservableObject, SwiftyTeethable {
    @Published var isScanning = false
    @Published var peripherals = [Device]()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        swiftyTeeth.state()
            .sink { (state) in
                print("Bluetooth State is: \(state)")
            }.store(in: &cancellables)
    }
    
    func scan(timeout: Int = 5) {
        print("Starting scan for nearby peripherals with timeout: \(timeout)")
        // TODO: Make isScanning part of the reactive chain
        // TODO: Figure out how to use the sink alternative, without a mem leak
        isScanning = true
        swiftyTeeth.scan(for: TimeInterval(timeout))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] (complete) in
                self?.isScanning = false
            }) { [weak self] (devices) in
                self?.peripherals = devices
            }.store(in: &cancellables)
    }
}

struct PeripheralRow: View {
    let name: String
    var body: some View {
        HStack {
            Text("\(name)")
            Spacer()
        }
    }
}
struct ScanningView: View {
    @ObservedObject var vm = ScanningViewModel()
    
    private var scanButton: some View {
        Button("Scan") {
            self.vm.scan(timeout: 3)
        }.disabled(vm.isScanning == true)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.vm.peripherals) { peripheral in
                    NavigationLink(destination: PeripheralView(peripheral: peripheral)) {
                        PeripheralRow(name: peripheral.name)
                    }
                    
                }
            }.listStyle(GroupedListStyle())
            .navigationBarTitle("Scanning", displayMode: .inline)
            .navigationBarItems(trailing: scanButton)
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView()
    }
}
