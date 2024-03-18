BLE Device Subscriber
---
This is a SwiftUI app that connects to a Bluetooth Low Energy (BLE) device and subscribes to a characteristic value to receive data from the device. The app is designed to handle the complete BLE communication process, including scanning, connecting, discovering services and characteristics, and receiving data updates.

Features
---
Scans for a specific BLE device based on a predefined UUID.
Connects to the discovered device and establishes a connection.
Discovers available services and characteristics on the connected device.
Subscribes to a specific characteristic to receive data updates.
Displays the connection status and received data in the app's user interface.
Processes the received hex string data to extract a temperature value in Celsius.

Usage
---
Build and run the app on a compatible iOS device or simulator.
Ensure that Bluetooth is enabled on your device.
Tap the "Start Scanning" button to initiate the scanning process.
The app will search for the BLE device with the predefined UUID.
Once the device is found, the app will connect to it and display the connection status.
After successful connection, the app will discover the available services and characteristics on the device.
The app will subscribe to the characteristic with the predefined UUID to receive data updates.
The received data will be displayed in the app's user interface, along with the connection status.

Code Structure
---
The app consists of two main components:

BLEManager: This class handles all BLE operations, including scanning, connecting, discovering services and characteristics, and receiving data updates. It conforms to the CBCentralManagerDelegate and CBPeripheralDelegate protocols to handle the respective Bluetooth events.

ContentView: This SwiftUI view represents the app's user interface, displaying the connection status, received data, and the "Start Scanning" button. It uses the BLEManager class to manage the BLE operations.

Dependencies
---
This app uses the following frameworks and libraries:
CoreBluetooth
SwiftUI

License
---
This project is licensed under the Cathay License.
Feel free to modify and enhance the code as needed for your specific use case.
