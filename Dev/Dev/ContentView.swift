import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?

    @Published var statusMessage = "Ready"
    @Published var receivedData = "Waiting for data..."

    let deviceAddress = "1119CD9B-580D-D137-BC72-69BA354FFCCE"
    let characteristicUUIDs = [CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            statusMessage = "Scanning..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        } else {
            statusMessage = "Bluetooth is not ready."
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is On."
        case .poweredOff:
            statusMessage = "Bluetooth is Off."
        default:
            statusMessage = "Unknown Bluetooth status."
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.identifier.uuidString == deviceAddress {
            self.peripheral = peripheral
            centralManager.stopScan()
            statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Connected to \(peripheral.name ?? "")"
        peripheral.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            peripheral.discoverServices([CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")])
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristicUUIDs.contains(characteristic.uuid) {
            statusMessage = "Discovered characteristic \(characteristic.uuid), waiting to read value..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, characteristic.uuid == CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb") {
            DispatchQueue.main.async {
                self.receivedData = String(data: value, encoding: .utf8) ?? "Invalid data"
                self.statusMessage = "Received data: \(self.receivedData)"
            }
        } else {
            statusMessage = "Error or invalid data received."
        }
    }
}



struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        VStack {
            Text("Status: \(bleManager.statusMessage)")
                .font(.headline)
                .padding()

            Text("Data: \(bleManager.receivedData)")
                .font(.body)
                .padding()

            Button("Start Scanning") {
                bleManager.startScanning()
            }
            .padding()
        }
    }
}

//import SwiftUI
//
//struct ContentView: View {
//    @State private var temperature: String = "未知"
//
//    var body: some View {
//        VStack {
//            Text("額溫: \(temperature)")
//                .font(.title)
//                .padding()
//
//            Button(action: {
//                // 生成一個介於 35.5 至 40 度之間的隨機溫度
//                let randomTemperature = Double.random(in: 35.5...40.0)
//                // 更新溫度狀態，並格式化到小數點後一位
//                self.temperature = String(format: "%.1f°C", randomTemperature)
//            }) {
//                Text("讀取額溫")
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//        }
//    }
//}


//import SwiftUI
//
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Knock, knock!")
//        }
//        .padding()
//    }
//}
//
//
//#Preview {
//    ContentView()
//}

////
////  ContentView.swift
////  Dev
////
////  Created by CFH00892977 on 2024/2/27.
////
//
//import SwiftUI
//import CoreData
//
//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
//                    } label: {
//                        Text(item.timestamp!, formatter: itemFormatter)
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//#if os(iOS)
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//#endif
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { items[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//}
//
//private let itemFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .medium
//    return formatter
//}()
//
//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
