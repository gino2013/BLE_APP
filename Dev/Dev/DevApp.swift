//
//  DevApp.swift
//  Dev
//
//  Created by CFH00892977 on 2024/2/27.
//

import SwiftUI

@main
struct DevApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
