import SwiftUI
import MapKit

struct SightingPinInformationView: View {
    let waypoint: Waypoint

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(.secondary).frame(width: 44, height: 5).padding(.top, 8)

            switch waypoint {
            case .sighting(let s):
                Text("\(s.species.emoji) \(s.species.name)").font(.title3).bold()
                Text("Observed \(RelativeDateTimeFormatter().localizedString(for: s.createdAt, relativeTo: .now))")
                    .foregroundStyle(.secondary)
                if let note = s.note { Text(note) }
                Map(initialPosition: .region(.init(center: s.coordinate, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005))))
                    .frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))

            case .hotspot(let h):
                Text(h.name).font(.title3).bold()
                Text("High Volume Area • density \(Int(h.densityScore * 100))")
                    .foregroundStyle(.secondary)
                Map(initialPosition: .region(.init(center: h.coordinate, span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))))
                    .frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer(minLength: 0)
        }
        .padding()
        .presentationDetents([.fraction(0.35), .medium])
    }
}