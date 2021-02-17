//
//  CombineView.swift
//  CodableNetworking
//
//  Created by Sergio Rodríguez Rama on 17/2/21.
//

import SwiftUI
import Combine

struct User: Decodable {
    var id: UUID
    var name: String

    static let `default` = User(id: UUID(), name: "Anonymous")
}

struct CombineView: View {

    @State private var requests = Set<AnyCancellable>()

    var body: some View {
        Button("Fetch data") {
            let url = URL(string: "https://www.hackingwithswift.com/samples/user-24601.json")!
            self.fetch(url, defaultValue: User.default) {
                print($0.name)
            }
        }
    }

    // MARK: - URLSession

    func fetch(_ url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                print(User.default.name)
            } else if let data = data {
                let decoder = JSONDecoder()
                do {
                    let user = try decoder.decode(User.self, from: data)
                    print(user.name)
                } catch {
                    print(User.default.name)
                }
            }
        }.resume()
    }

    // MARK: - Combine

    func fetch<T: Decodable>(_ url: URL, defaultValue: T, completion: @escaping (T) -> Void) {
        let decoder = JSONDecoder()
        URLSession.shared.dataTaskPublisher(for: url)
            .retry(1)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .replaceError(with: defaultValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: completion)
            .store(in: &requests)
    }
}

struct CombineView_Previews: PreviewProvider {
    static var previews: some View {
        CombineView()
    }
}
