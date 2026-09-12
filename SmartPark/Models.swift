import Foundation
import CoreLocation

enum ParkingAvailability: String, Codable, CaseIterable, Identifiable {
    case available = "Available"
    case limited = "Limited"
    case full = "Full"

    var id: String { rawValue }
}

struct ParkingSpot: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let pricePerHour: Double
    let distanceMiles: Double
    let availability: ParkingAvailability
    let address: String
    let score: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var priceText: String {
        "$\(Int(pricePerHour))/hr"
    }

    var availabilityText: String {
        availability.rawValue
    }

    var distanceText: String {
        String(format: "%.1f miles", distanceMiles)
    }
}

struct NominatimResult: Decodable {
    let lat: String
    let lon: String
    let display_name: String?
}

struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

struct OverpassElement: Decodable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

struct OverpassCenter: Decodable {
    let lat: Double
    let lon: Double
}

