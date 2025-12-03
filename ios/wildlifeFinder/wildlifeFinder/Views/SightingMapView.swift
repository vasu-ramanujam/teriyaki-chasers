import SwiftUI
import MapKit

struct SightingMapView: View {
    @Environment(SightingMapViewModel.self) private var model

    // iOS 17 map camera
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Sheets
    @State private var showSightingSheet = false
    @State private var showHVASheet = false
    @State private var showRouteSheet = false

    // Inputs for your SightingPinInformationView
    @State private var selectedSighting: sightingSheetInfo?
    @State private var selectedHotspot: hotspotSheetInfo?

    // RouteViewModel stuff
    @Environment(RouteViewModel.self) private var routeVM

    var body: some View {
        @Bindable var vm = model
        ZStack(alignment: .bottom) {
            mapLayer

            VStack(spacing: 12) {
                // Search bar + suggestions
                SearchBarView(
                    text: $vm.searchText,
                    placeholder: "Search",
                    onSubmit: {
                        model.selectedSpecies = model.searchText.isEmpty ? nil : model.searchText
                        model.suggestions = []
                    },
                    onChange: { _ in model.updateSuggestions() },
                    onClear: { model.clearFilter() },
                    suggestions: model.suggestions,
                    onPickSuggestion: { pick in
                        model.searchText = pick
                        model.selectedSpecies = pick
                        model.suggestions = []
                    }
                )
                .padding(.horizontal)

                HStack {
                    Text(model.selectedSpecies == nil ? "No filters applied." : "Filtered by species: \(model.selectedSpecies!)")
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
                        Button { 
                            Task {
                                await model.call_loadSightings()
                                await model.loadHVA()
                            }
                        } label: { 
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(model.isLoading ? .orange : .primary)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.top, 7)

                    Button {
                        showRouteSheet = true
                        
                        Task {
                            await routeVM.buildRoute(from: Array(model.selectedWaypoints))
                        }
                    } label: {
                        Text("Generate Route")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .disabled(!model.canGenerateRoute)
                    .tint(ui_orange)
                    .opacity(model.canGenerateRoute ? 1 : 0.5)
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.black)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                }
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            // Load real data instead of mock
            Task {
                // Wait briefly for GPS; then center & load last-24h sightings
                await model.centerOnFirstValidLocationAndLoad()
                await model.loadHVA()
                cameraPosition = .region(model.mapRegion)
            }
        }
        .sheet(item: $selectedSighting) { item in
            SightingPinInformationView(
                sighting: item.sighting,
                origin: .map,
                waypointObj: item.waypoint
            )
        }
        .sheet(item: $selectedHotspot) { item in
            HVAPinInformationView(hotspotObj: item.waypoint)
        }
        .sheet(isPresented: $showRouteSheet) {
            RouteStackView()
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if model.isLoading {
                VStack {
                    ProgressView("Loading sightings...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .alert("Error", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if model.showSightings {
                ForEach(model.filteredSightings) { s in
                    Annotation("\(s.species.name)", coordinate: s.coordinate) {
                        PinButton(icon: "mappin.circle.fill", color: .green) {
                            selectedSighting = sightingSheetInfo(sighting: s,
                                                                 waypoint: .sighting(s))
                        }
                        .contextMenu {
                            Button(model.selectedWaypoints.contains(.sighting(s)) ? "Remove from route" : "Add to route") {
                                model.toggleWaypoint(.sighting(s))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if model.selectedWaypoints.contains(.sighting(s)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }

            if model.showHotspots {
                ForEach(model.hotspots) { h in
                    Annotation(h.name, coordinate: h.coordinate) {
                        PinButton(icon: "flame.circle.fill", color: .orange) {
                            selectedHotspot = hotspotSheetInfo(hotspot: h,
                                                                 waypoint: .hotspot(h))
                        }
                        .contextMenu {
                            Button(model.selectedWaypoints.contains(.hotspot(h)) ? "Remove from route" : "Add to route") {
                                model.toggleWaypoint(.hotspot(h))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if model.selectedWaypoints.contains(.hotspot(h)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .onMapCameraChange { context in
            model.mapRegion.center = context.camera.centerCoordinate
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

private struct sightingSheetInfo: Identifiable {
    let id = UUID()
    let sighting: Sighting
    let waypoint: Waypoint
}

private struct hotspotSheetInfo: Identifiable {
    let id = UUID()
    let hotspot: Hotspot
    let waypoint: Waypoint
}

