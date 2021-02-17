//
//  UserFriendlyNetworkingView.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 17/2/21.
//

import SwiftUI
import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")

    var isActive = false
    var isExpensive = false
    var isConstrained = false
    var connectionType = NWInterface.InterfaceType.other

    init() {
        monitor.pathUpdateHandler = { path in
            self.isActive = path.status == .satisfied
            self.isExpensive = path.isExpensive
            self.isConstrained = path.isConstrained

            let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
            self.connectionType = connectionTypes.first(where: { path.usesInterfaceType($0) }) ?? .other

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }

        monitor.start(queue: queue)
    }
}

struct UserFriendlyNetworkingView: View {
    @State var fetched: String = ""
    @EnvironmentObject var network: NetworkMonitor

    var body: some View {
        VStack(spacing: 50) {
            Text(verbatim: """
                Active: \(network.isActive)
                Expensive: \(network.isExpensive)
                Constrained: \(network.isConstrained)
            """)
            Button {
                fetched = ""
                makeRequest()
            } label: {
                Text("Fetch data")
            }
            Text(fetched)
        }
    }

    func makeRequest() {
        let config = URLSessionConfiguration.default
        config.allowsExpensiveNetworkAccess = false
        config.allowsConstrainedNetworkAccess = false
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession.init(configuration: config)
        let url = URL(string: "http://www.apple.com")!

        session.dataTask(with: url) { data, response, error in
            fetched = "Fetched"
        }.resume()
    }
}

struct UserFriendlyNetworkingView_Previews: PreviewProvider {
    static var previews: some View {
        UserFriendlyNetworkingView()
    }
}
