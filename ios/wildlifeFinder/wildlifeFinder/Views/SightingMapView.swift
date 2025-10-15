import SwiftUI
import MapKit

struct SightingMapView: View {
    @StateObject private var vm = SightingMapViewModel()
    @State private var showRouteSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            VStack(spacing: 12) {
                // Search bar + suggestions
                SearchBarView(
                    text: $vm.searchText,
                    placeholder: "Search",
                    onSubmit: {
                        vm.selectedSpecies = vm.searchText.isEmpty ? nil : vm.searchText
                        vm.suggestions = []
                    },
                    onChange: { _ in vm.updateSuggestions() },
                    onClear: { vm.clearFilter() },
                    suggestions: vm.suggestions,
                    onPickSuggestion: { pick in
                        vm.searchText = pick
                        vm.selectedSpecies = pick
                        vm.suggestions = []
                    }
                )
                .padding(.horizontal)

                HStack {
                    Text(vm.selectedSpecies == nil ? "No filters applied." : "Filtered by species: \(vm.selectedSpecies!)")
                        .font(.callout).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ToggleChip(title: "Sighting Pin", isOn: $vm.showSightings)
                        ToggleChip(title: "High Volume Area", isOn: $vm.showHotspots)
                        Spacer()
                        Button { } label: { Image(systemName: "scope") }
                            .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)

                    Button {
                        showRouteSheet = true
                    } label: {
                        Text("Generate Route")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .disabled(!vm.canGenerateRoute)
                    .opacity(vm.canGenerateRoute ? 1 : 0.5)
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(.ultraThinMaterial)
            }
        }
        .onAppear { vm.loadMock() }
        .sheet(item: $vm.selectedPin) { pin in
            SightingPinInformationView(waypoint: pin)
                .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showRouteSheet) {
            RouteStackView(waypoints: Array(vm.selectedWaypoints))
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var mapLayer: some View {
        Map(position: .region($vm.mapRegion)) {
            if vm.showSightings {
                ForEach(vm.filteredSightings) { s in
                    Annotation("\(s.species.emoji) \(s.species.name)", coordinate: s.coordinate) {
                        PinButton(icon: "mappin.circle.fill", color: .green) {
                            vm.selectedPin = .sighting(s)
                        }
                        .contextMenu {
                            Button(vm.selectedWaypoints.contains(.sighting(s)) ? "Remove from route" : "Add to route") {
                                vm.toggleWaypoint(.sighting(s))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if vm.selectedWaypoints.contains(.sighting(s)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }

            if vm.showHotspots {
                ForEach(vm.hotspots) { h in
                    Annotation(h.name, coordinate: h.coordinate) {
                        PinButton(icon: "flame.circle.fill", color: .orange) {
                            vm.selectedPin = .hotspot(h)
                        }
                        .contextMenu {
                            Button(vm.selectedWaypoints.contains(.hotspot(h)) ? "Remove from route" : "Add to route") {
                                vm.toggleWaypoint(.hotspot(h))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if vm.selectedWaypoints.contains(.hotspot(h)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Local UI helpers
private struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Button { isOn.toggle() } label: {
            Text(title)
                .font(.callout).bold()
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(isOn ? Color.orange.opacity(0.25) : Color.gray.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PinButton: View {
    let icon: String
    let color: Color
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}
