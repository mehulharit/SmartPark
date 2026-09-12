import Foundation
import CoreLocation

final class ParkingAPIService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "SmartPark/1.0 (student project)"
        ]
        return URLSession(configuration: config)
    }()

    func geocodeLocation(query: String) async throws -> CLLocationCoordinate2D {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://nominatim.openstreetmap.org/search?q=\(encoded)&format=jsonv2&limit=1")!

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "SmartPark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to search location."])
        }

        let results = try JSONDecoder().decode([NominatimResult].self, from: data)
        guard let first = results.first,
              let lat = Double(first.lat),
              let lon = Double(first.lon) else {
            throw NSError(domain: "SmartPark", code: 2, userInfo: [NSLocalizedDescriptionKey: "No matching location found."])
        }

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func fetchParkingNear(latitude: Double, longitude: Double, radius: Int = 1500) async throws -> [ParkingSpot] {
        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="parking"](around:\(radius),\(latitude),\(longitude));
          way["amenity"="parking"](around:\(radius),\(latitude),\(longitude));
          relation["amenity"="parking"](around:\(radius),\(latitude),\(longitude));
        );
        out center tags;
        """

        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NSError(domain: "SmartPark", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to load parking data."])
        }

        let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)

        let spots = decoded.elements.compactMap { element -> ParkingSpot? in
            let lat = element.lat ?? element.center?.lat
            let lon = element.lon ?? element.center?.lon
            guard let lat, let lon else { return nil }

            let coordinate = CLLocation(latitude: lat, longitude: lon)
            let distanceMiles = userLocation.distance(from: coordinate) / 1609.34

            let tags = element.tags ?? [:]
            let name = tags["name"] ?? "Parking Spot \(element.id)"
            let address = tags["addr:full"] ?? tags["addr:street"] ?? "Address not listed"
            let price = estimatePrice(from: tags)
            let availability = estimateAvailability(from: tags)
            let score = calculateScore(distanceMiles: distanceMiles, pricePerHour: price, availability: availability)

            return ParkingSpot(
                id: String(element.id),
                name: name,
                latitude: lat,
                longitude: lon,
                pricePerHour: price,
                distanceMiles: distanceMiles,
                availability: availability,
                address: address,
                score: score
            )
        }

        return spots.sorted { $0.score > $1.score }
    }

    private func estimatePrice(from tags: [String: String]) -> Double {
        if let fee = tags["fee"], fee.lowercased() == "no" {
            return 0
        }

        if let parkingType = tags["parking"]?.lowercased() {
            switch parkingType {
            case "multi-storey", "underground":
                return 6
            case "surface":
                return 4
            default:
                return 5
            }
        }

        if let fee = tags["fee"], fee.lowercased() == "yes" {
            return 5
        }

        return 4
    }

    private func estimateAvailability(from tags: [String: String]) -> ParkingAvailability {
        if let access = tags["access"]?.lowercased(),
           access == "no" || access == "private" {
            return .full
        }

        if let capacity = tags["capacity"], let capacityValue = Int(capacity), capacityValue < 10 {
            return .limited
        }

        return .available
    }

    private func calculateScore(distanceMiles: Double, pricePerHour: Double, availability: ParkingAvailability) -> Double {
        let distanceScore = max(0, 3.0 - distanceMiles) * 25
        let priceScore = max(0, 10.0 - pricePerHour) * 4
        let availabilityScore: Double
        switch availability {
        case .available: availabilityScore = 20
        case .limited: availabilityScore = 10
        case .full: availabilityScore = 0
        }
        return distanceScore + priceScore + availabilityScore
    }
}
