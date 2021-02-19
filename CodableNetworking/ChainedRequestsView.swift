//
//  ChainedRequestsView.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 18/2/21.
//

import SwiftUI
import Combine

struct NewsItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
    let main_image: String
    let published_date: Date
}

struct ChainedRequestsView: View {

    @State private var requests = Set<AnyCancellable>()
    @State private var items = [NewsItem]()

    var body: some View {
        NavigationView {
            VStack {
                Button {
                    let url = URL(string: "https://www.hackingwithswift.com/samples/news.json")!
                    self.fetch(url, defaultValue: [URL]())
                        .flatMap { urls in
                            urls.publisher.flatMap { url in
                                fetch(url, defaultValue: [NewsItem]())
                            }
                        }
                        .collect()
                        .sink { values in
                            items = values
                                .flatMap { $0 }
                                .sorted { $0.id > $1.id }
                        }
                        .store(in: &requests)
                } label: {
                    Text("Fetch news")
                }
                List(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.strap)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Hacking with Swift")
        }
    }

    func fetch<T: Decodable>(_ url: URL, defaultValue: T) -> AnyPublisher<T, Never> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .replaceError(with: defaultValue)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

struct ChainedRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        ChainedRequestsView()
    }
}
