# HWS - Networking

Combine, Network access, Codable.

### Bibliography

https://www.hackingwithswift.com/plus/networking/codable-networking-with-combine
https://www.hackingwithswift.com/plus/networking/user-friendly-network-access
https://www.hackingwithswift.com/plus/networking/uploading-codable-data
https://www.hackingwithswift.com/plus/networking/merging-multiple-requests-with-combine
https://www.hackingwithswift.com/plus/networking/creating-chained-network-requests-with-combine

## Codable networking with Combine

Combine can decode the result of a request, handle errors, retry the request n times, give default values in case it fails, get the result in a closure, run the closure in a specific thread... All in once!

```swift
func fetch<T: Decodable>(_ url: URL, defaultValue: T, completion: @escaping (T) -> Void) {
    let decoder = JSONDecoder()
    URLSession.shared.dataTaskPublisher(for: url)
        .retry(1)                                // Retry the request only once, if it fails.
        .map(\.data)                             // Interested in its data only.
        .decode(type: T.self, decoder: decoder)  // Decode the data as the given Decodable.
        .replaceError(with: defaultValue)        // If there is an error, return a default value.
        .receive(on: DispatchQueue.main)         // Send the result to the main thread.
        .sink(receiveValue: completion)          // Pass the result to a closure.
        .store(in: &requests)                    // Store the request to keep it alive.
}
```

Must call `.receive(on: DispatchQueue.main)` always before `.sink(receiveValue: completion)`, to know in advance in which thread the closure will be run.

## User-friendly network access

Access data of network connection and make it observable with SwiftUI:

```swift
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")

    var isExpensive = false // if WiFi -> false, if Cellular -> true

    init() {
        monitor.pathUpdateHandler = { path in
            self.isExpensive = path.isExpensive
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        monitor.start(queue: queue)
    }
}
```

Observe it as an environment object:

```swift
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
```

Update the view automatically when the connection status change:

```swift
struct UserFriendlyNetworkingView: View {
    @EnvironmentObject var network: NetworkMonitor

    var body: some View {
        Text(verbatim: "Active: \(network.isActive)")
    }
}
```

Make a request that waits until the connection is not expensive:

```swift
func makeRequest() {
    let config = URLSessionConfiguration.default
    config.allowsExpensiveNetworkAccess = false
    config.allowsConstrainedNetworkAccess = false
    config.waitsForConnectivity = true
    config.requestCachePolicy = .reloadIgnoringLocalCacheData

    let session = URLSession.init(configuration: config)
    let url = URL(string: "http://www.apple.com")!

    session.dataTask(with: url) { data, response, error in
        print("The connection is not expensive anymore, so the data has been fetched!")
    }.resume()
}
```

## Uploading codable data

[ReqRes](https://reqres.in) offers a great API against which you can test your front-end.

By default, `dataTaskPublisher` request method is GET. In order to make a POST request with Combine, an URLRequest must be created:

```swift
func upload<Input: Encodable, Output: Decodable>(_ data: Input, url: URL, httpMethod: String = "POST", contentType: String = "application/json", completion: @escaping (Result<Output, UploadError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(data)
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Output.self, decoder: JSONDecoder())
            .map(Result.success)
            .catch { error -> Just<Result<Output, UploadError>> in
                error is DecodingError
                    ? Just(.failure(.decodeFailed))
                    : Just(.failure(.uploadFailed))
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: completion)
            .store(in: &requests)
    }
```

`Just` is a kind of publisher that emits an output to each subscriber and then finishes, it's perfect for emitting errors.

## Merging multiple requests with Combine

With `Zip`, multiple requests can be merged:

```swift
let messagesURL = URL(string: "https://www.hackingwithswift.com/samples/user-messages.json")!
let messagesTask = fetch(messagesURL, defaultValue: [Message]())
let favoritesURL = URL(string: "https://www.hackingwithswift.com/samples/user-favorites.json")!
let favoritesTask = fetch(favoritesURL, defaultValue: Set<Int>())
let combined = Publishers.Zip(messagesTask, favoritesTask)
```

The `sink` completion will run when all the zipped requests had finished and the parameters of the closure are the results of the requests in the corresponding order: 

```swift
combined.sink { messages, favorites in
    self.messages = messages
    self.favorites = favorites
}
```

You can prove that this works, adding a random delay to each request, to make more clear that the view is populated all at once instead of step by step:

```swift
URLSession.shared.dataTaskPublisher(for: url)
    .delay(for: .seconds(Double.random(in: 1...5)), scheduler: RunLoop.main)
```

Each publisher is not sinked immediately, the sink is done once all the publishers had been created.

So, `eraseToAnyPublisher` must be called at the end of every publisher declaration. Otherwise, this compilation error will appear:

```
Publishers.ReplaceError<Publishers.Decode<Publishers.MapKeyPath<Publishers.Retry<URLSession.DataTaskPublisher>, Data>, T, JSONDecoder>>
```

## Creating chaining network requests with Combine

When the result of a `map` are multiple publishers, `flatMap` should be used instead.

It's different calling `flatMap` in an `Sequence` than in a `Publisher`. In the former, an array of arrays will become an array, in the latest, a publisher of publishers will become a publisher.

```swift
self.fetch(url, defaultValue: [URL]())
    .flatMap { urls in                             // Publisher flatMap
        urls.publisher.flatMap { url in            // Publisher flatMap
            fetch(url, defaultValue: [NewsItem]())
        }
    }
    .collect()
    .sink { values in
        items = values
        .flatMap { $0 }                            // Sequence flatMap
        .sorted { $0.id > $1.id }
    }
    .store(in: &requests)
```

A `Sequence` publisher will emit multiple values if allowed. So `sink` will be called multiple times, if we only want it to be called once, with the last value emitted, `collect()` must be used:
```swift
.flatMap { urls in
    urls.publisher.flatMap { url in
        fetch(url, defaultValue: [NewsItem]())
    }
}
.collect()
```