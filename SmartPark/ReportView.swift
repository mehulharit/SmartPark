import SwiftUI
import SwiftData

struct ReportView: View {
    let spot: ParkingSpot

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatus = "Available"
    @State private var notes = ""

    let options = [
        ("Available", "Parking spots are available"),
        ("Full", "No available spots"),
        ("Incorrect Information", "Details are wrong or outdated")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help keep parking information accurate by reporting the current status.")
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button {
                        selectedStatus = option.0
                    } label: {
                        HStack {
                            Image(systemName: selectedStatus == option.0 ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.0)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(option.1)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(selectedStatus == option.0 ? Color.blue.opacity(0.12) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedStatus == option.0 ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)

            TextField("Optional notes...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Spacer()

            Button {
                submitReport()
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Report Parking Status")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitReport() {
        let report = ParkingReport(spot: spot, status: selectedStatus, notes: notes)
        modelContext.insert(report)
        try? modelContext.save()
        dismiss()
    }
}
