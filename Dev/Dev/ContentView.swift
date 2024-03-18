import CoreBluetooth
import SwiftUI

// BLEManager class is responsible for managing all Bluetooth Low Energy (BLE) operations,
// including scanning for devices, connecting to peripherals, and handling data communication.
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // CBCentralManager instance to manage the Bluetooth operations
    var centralManager: CBCentralManager!
    // CBPeripheral instance representing the peripheral device that the app connects to
    var peripheral: CBPeripheral?

    // Published properties to notify the UI about status and data changes
    @Published var statusMessage = "Ready"
    @Published var receivedData = "Waiting for data..."

    // UUIDs for filtering devices and characteristics
    let deviceAddress = "1FE8527F-87F3-7D8B-BC84-9BA529FB8BAA"
    let characteristicUUIDs = [CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")]

    // Initializer to set up the CBCentralManager instance
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    // Function to start scanning for peripheral devices
    func startScanning() {
        if centralManager.state == .poweredOn {
            statusMessage = "Scanning..."
            // Delay the scanning process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        } else {
            statusMessage = "Bluetooth is not ready."
        }
    }

    // Delegate method to handle updates in the Bluetooth state
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

    // Delegate method to handle discovery of a peripheral device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.identifier.uuidString == deviceAddress {
            self.peripheral = peripheral
            centralManager.stopScan()
            statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
            // Delay the connection process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }

    // Delegate method to handle successful connection to a peripheral device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Connected to \(peripheral.name ?? "")"
        peripheral.delegate = self
        // Delay the service discovery process by 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            peripheral.discoverServices([CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")])
        }
    }

    // Delegate method to handle the discovery of services for a connected peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        let interestedCharacteristicUUIDs = [CBUUID(string: "fff1")]
        for service in services {
            statusMessage = ("Discovered service: \(service.uuid)")
            // Delay the characteristic discovery process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                peripheral.discoverCharacteristics(interestedCharacteristicUUIDs, for: service)
            }
        }
    }
    
    // Delegate method to handle the discovery of characteristics for a service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            statusMessage = ("Characteristic UUID: \(characteristic.uuid), properties: \(characteristic.properties)")
            if characteristic.properties.contains(.read) {
                statusMessage = ("Characteristic \(characteristic.uuid) is readable")
                peripheral.readValue(for: characteristic)
            } else if characteristic.properties.contains(.notify) {
                statusMessage = ("Characteristic \(characteristic.uuid) supports notifications. Subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    // Delegate method to handle updates in the value of a characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, characteristic.uuid == CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb") {
            let hexString = value.map { String(format: "%02hhx", $0) }.joined()
            
            DispatchQueue.main.async {
                if let convertedData = self.processHexString(hexString) {
                    self.receivedData = String(format: "%.2f°C", convertedData)
                    self.statusMessage = "Received raw data: \(hexString)"
                } else {
                    self.statusMessage = "Error in processing data."
                }
            }
        }
    }
    
    // Utility function to process the received hex string data
    func processHexString(_ hexString: String) -> Double? {
        // Ensure the string length is at least 8 characters
        guard hexString.count >= 8 else { return nil }

        // Extract and convert the substring "233b" (from index 10 to 13)
        let startIndex = hexString.index(hexString.startIndex, offsetBy: 10)
        let endIndex = hexString.index(hexString.startIndex, offsetBy: 13)
        let subString = String(hexString[startIndex...endIndex]) // "233b"

        // Extract and convert "23" and "3b"
        if let firstPart = Int(subString.prefix(2), radix: 16),
           let secondPart = Int(subString.suffix(2), radix: 16) {
            // Calculate the final result
            return Double(secondPart) * 0.01 + Double(firstPart)
        } else {
            return nil
        }
    }
}

// SwiftUI view to display the app UI
struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        ZStack {
            Color(red: 0.68, green: 0.85, blue: 1).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Spacer()

                // App title
                Text("BLE Device Subscriber")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Status and Data display with visual enhancements
                VStack {
                    // Display connection status
                    Text("Status: \(bleManager.statusMessage)")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.yellow.opacity(0.85))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )

                    // Display received data
                    Text("Data: \(bleManager.receivedData)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.black.opacity(0.55))
                        .padding()
                        .background(Color.green.opacity(0.55))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .frame(width: 300, height: 60)
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(.horizontal, 20)

                // Start scanning button with 3D effect
                Button(action: {
                    withAnimation {
                        bleManager.startScanning()
                    }
                }) {
                    Text("Start Scanning")
                        .font(.title2)
                        .foregroundColor(.white)
                        .bold()
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(20)
                        .shadow(color: .blue, radius: 2, x: 2, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 1)
                                .shadow(color: .white, radius: 2, x: -2, y: -2)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        )
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding()
        }
    }
}

// Preview provider for SwiftUI previews in Xcode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(bleManager: BLEManager())
    }
}


//
//struct ContentView: View {
//    @ObservedObject var bleManager = BLEManager()
//
//    var body: some View {
//        VStack {
//            Text("Status: \(bleManager.statusMessage)")
//                .font(.headline)
//                .padding()
//
//            Text("Data: \(bleManager.receivedData)")
//                .font(.title) // 放大字体
//                .foregroundColor(.yellow) // 设置字体颜色为黄色
//                .padding()
//
//            Button(action: {
//                bleManager.startScanning()
//            }) {
//                Text("Start Scanning")
//                    .foregroundColor(.blue) // 设置按钮文字颜色为蓝色
//                    .padding()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20)
//                            .stroke(Color.blue, lineWidth: 2) // 设置边框为蓝色
//                    )
//                    .background(Color.white) // 设置按钮背景颜色为白色
//                    .cornerRadius(20) // 设置圆角
//            }
//            .padding()
//        }
//    }
//}


//
//struct ContentView: View {
//    @ObservedObject var bleManager = BLEManager()
//
//    var body: some View {
//        VStack {
//            Text("Status: \(bleManager.statusMessage)")
//                .font(.headline)
//                .padding()
//
//            Text("Data: \(bleManager.receivedData)")
//                .font(.body)
//                .padding()
//
//            Button("Start Scanning") {
//                bleManager.startScanning()
//            }
//            .padding()
//        }
//    }
//}

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
