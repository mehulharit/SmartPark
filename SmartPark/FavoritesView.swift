import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \FavoriteParking.addedAt, order: .reverse) private var favorites: [FavoriteParking]

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Saved parking spots will appear here.")
                )
            } else {
                List {
                    ForEach(favorites) { favorite in
                        NavigationLink {
                            ParkingDetailFromFavoriteView(favorite: favorite)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(favorite.name)
                                    .font(.headline)

                                HStack(spacing: 8) {
                                    Text("$\(Int(favorite.pricePerHour))/hr")
                                    Text("•")
                                    Text(String(format: "%.1f miles", favorite.distanceMiles))
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)

                                Text(favorite.availability.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ParkingDetailFromFavoriteView: View {
    let favorite: FavoriteParking

    var body: some View {
        ParkingDetailView(
            spot: ParkingSpot(
                id: favorite.spotID,
                name: favorite.name,
                latitude: favorite.latitude,
                longitude: favorite.longitude,
                pricePerHour: favorite.pricePerHour,
                distanceMiles: favorite.distanceMiles,
                availability: favorite.availability,
                address: favorite.address,
                score: 0
            )
        )
    }
}
