import Foundation
import Combine
import MapKit
import CoreLocation

@MainActor
final class ParkingViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var spots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var maxPrice: Double = 10
    @Published var maxDistance: Double = 3
    @Published var onlyAvailable: Bool = false

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    private let apiService = ParkingAPIService()

    var filteredSpots: [ParkingSpot] {
        spots
            .filter { spot in
                spot.pricePerHour <= maxPrice &&
                spot.distanceMiles <= maxDistance &&
                (!onlyAvailable || spot.availability == .available)
            }
            .sorted { $0.score > $1.score }
    }

    var recommendedSpot: ParkingSpot? {
        filteredSpots.first
    }

    func updateLocation(_ coordinate: CLLocationCoordinate2D) {
        region.center = coordinate
    }

    func loadParkingNear(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil

        do {
            let parking = try await apiService.fetchParkingNear(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            spots = parking
        } catch {
            errorMessage = error.localizedDescription
            spots = []
        }

        isLoading = false
    }

    func searchAndLoad(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let coordinate = try await apiService.geocodeLocation(query: trimmed)
            region.center = coordinate
            let parking = try await apiService.fetchParkingNear(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            spots = parking
        } catch {
            errorMessage = error.localizedDescription
            spots = []
        }

        isLoading = false
    }

    func clearResults() {
        spots = []
    }
}
