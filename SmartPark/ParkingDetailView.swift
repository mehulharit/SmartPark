import SwiftUI
import SwiftData

struct ParkingDetailView: View {
    let spot: ParkingSpot

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var favorites: [FavoriteParking]

    private var isFavorite: Bool {
        favorites.contains { $0.spotID == spot.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(spot.name)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)

            DetailCard(title: "Price", value: spot.priceText)
            DetailCard(title: "Distance", value: spot.distanceText)
            DetailCard(title: "Availability", value: spot.availabilityText, subvalue: "\(Int(spot.score)) recommendation score")
            DetailCard(title: "Address", value: spot.address)

            Spacer()

            Button {
                toggleFavorite()
            } label: {
                Label(isFavorite ? "Saved to Favorites" : "Save Favorite",
                      systemImage: isFavorite ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            NavigationLink {
                DirectionsView(spot: spot)
            } label: {
                Label("Get Directions", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            NavigationLink {
                ReportView(spot: spot)
            } label: {
                Label("Report", systemImage: "flag")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4))
                    )
            }
        }
        .padding()
        .navigationTitle("Parking Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.spotID == spot.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteParking(spot: spot))
        }
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    var subvalue: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.blue)

            Text(value)
                .font(.body)

            if let subvalue {
                Text(subvalue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
