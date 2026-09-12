import SwiftUI
import CoreLocation
import Combine

@MainActor
final class AppLocationState: ObservableObject {
    @Published var didCompleteLocationSetup: Bool = false
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationName: String = ""
    @Published var usesManualLocation: Bool = false
}
