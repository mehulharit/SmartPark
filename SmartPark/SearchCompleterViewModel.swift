import Foundation
import Combine
import MapKit

@MainActor
final class SearchCompleterViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [String] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.map { result in
            if !result.title.isEmpty && !result.subtitle.isEmpty {
                return "\(result.title), \(result.subtitle)"
            } else if !result.title.isEmpty {
                return result.title
            } else {
                return result.subtitle
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        results = []
    }
}
