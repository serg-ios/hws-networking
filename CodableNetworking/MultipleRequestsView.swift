//
//  MultipleRequestsView.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 18/2/21.
//

import SwiftUI
import Combine

struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

struct MultipleRequestsView: View {
    @State private var requests = Set<AnyCancellable>()
    @State private var messages = [Message]()
    @State private var favorites = Set<Int>()

    var body: some View {
        NavigationView {
            List(messages) { message in
                HStack {
                    VStack(alignment: .leading) {
                        Text(message.from)
                            .font(.headline)
                        Text(message.message)
                            .foregroundColor(.secondary)
                    }

                    if favorites.contains(message.id) {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Messages")
        }
        .onAppear {
            let messagesURL = URL(string: "https://www.hackingwithswift.com/samples/user-messages.json")!
            let messagesTask = fetch(messagesURL, defaultValue: [Message]())
            let favoritesURL = URL(string: "https://www.hackingwithswift.com/samples/user-favorites.json")!
            let favoritesTask = fetch(favoritesURL, defaultValue: Set<Int>())
            let combined = Publishers.Zip(messagesTask, favoritesTask)
            combined.sink { messages, favorites in
                self.messages = messages
                self.favorites = favorites
            }
            .store(in: &requests)
        }
    }

    func fetch<T: Decodable>(_ url: URL, defaultValue: T) -> AnyPublisher<T, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
//            .delay(for: .seconds(Double.random(in: 1...5)), scheduler: RunLoop.main)
            .retry(1)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .replaceError(with: defaultValue)
            .eraseToAnyPublisher()
    }
}

struct MultipleRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        MultipleRequestsView()
    }
}
