import Foundation
import SwiftData

@Model
final class FavoriteParking {
    @Attribute(.unique) var spotID: String
    var name: String
    var pricePerHour: Double
    var distanceMiles: Double
    var availabilityRawValue: String
    var address: String
    var latitude: Double
    var longitude: Double
    var addedAt: Date

    init(spot: ParkingSpot) {
        self.spotID = spot.id
        self.name = spot.name
        self.pricePerHour = spot.pricePerHour
        self.distanceMiles = spot.distanceMiles
        self.availabilityRawValue = spot.availability.rawValue
        self.address = spot.address
        self.latitude = spot.latitude
        self.longitude = spot.longitude
        self.addedAt = Date()
    }

    var availability: ParkingAvailability {
        ParkingAvailability(rawValue: availabilityRawValue) ?? .available
    }
}

@Model
final class ParkingReport {
    var id: UUID
    var spotID: String
    var spotName: String
    var statusRawValue: String
    var notes: String
    var createdAt: Date

    init(spot: ParkingSpot, status: String, notes: String) {
        self.id = UUID()
        self.spotID = spot.id
        self.spotName = spot.name
        self.statusRawValue = status
        self.notes = notes
        self.createdAt = Date()
    }
}

@Model
final class ParkingPreferences {
    var id: UUID
    var maxPrice: Double
    var maxDistance: Double
    var onlyAvailable: Bool
    var availabilityAlertsEnabled: Bool
    var priceAlertsEnabled: Bool

    init() {
        self.id = UUID()
        self.maxPrice = 10
        self.maxDistance = 3
        self.onlyAvailable = false
        self.availabilityAlertsEnabled = true
        self.priceAlertsEnabled = false
    }
}

