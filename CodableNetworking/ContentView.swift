//
//  ContentView.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 17/2/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CombineView()
                .tag("combine")
                .tabItem {
                    Text("Combine")
                    Image(systemName: "suit.heart.fill")
                }
            UserFriendlyNetworkingView()
                .tag("networking")
                .tabItem {
                    Text("Networking")
                    Image(systemName: "network")
                }
            MultipleRequestsView()
                .tag("multiple")
                .tabItem {
                    Text("Multiple")
                    Image(systemName: "star.fill")
                }
            UploadView()
                .tag("upload")
                .tabItem {
                    Text("Upload")
                    Image(systemName: "icloud.and.arrow.up.fill")
                }
            ChainedRequestsView()
                .tag("chained")
                .tabItem {
                    Text("Chained")
                    Image(systemName: "link")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
