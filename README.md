# HWS - Networking

Combine, Network access, Codable.

### Bibliography

https://www.hackingwithswift.com/plus/networking/codable-networking-with-combine
https://www.hackingwithswift.com/plus/networking/user-friendly-network-access
https://www.hackingwithswift.com/plus/networking/uploading-codable-data

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

To make a POST request with Combine, an URLRequest must be created:

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



