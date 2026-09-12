import SwiftUI

struct ParkingRowView: View {
    let spot: ParkingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spot.name)
                .font(.headline)

            HStack(spacing: 8) {
                Text(spot.priceText)
                Text("•")
                Text(spot.distanceText)
            }
            .font(.subheadline)
            .foregroundColor(.blue)

            Text(spot.availabilityText)
                .font(.subheadline)
                .foregroundColor(colorForAvailability(spot.availability))
        }
        .padding(.vertical, 8)
    }

    private func colorForAvailability(_ availability: ParkingAvailability) -> Color {
        switch availability {
        case .available: return .green
        case .limited: return .orange
        case .full: return .red
        }
    }
}
