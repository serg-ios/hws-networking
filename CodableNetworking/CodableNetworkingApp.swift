//
//  CodableNetworkingApp.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 17/2/21.
//

import SwiftUI

@main
struct CodableNetworkingApp: App {
    var body: some Scene {
        WindowGroup {
            let monitor = NetworkMonitor()
            ContentView()
                .environmentObject(monitor)
        }
    }
}
