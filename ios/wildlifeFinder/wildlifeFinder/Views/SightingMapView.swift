import SwiftUI
import MapKit

struct SightingMapView: View {
    @EnvironmentObject private var vm: SightingMapViewModel

    // iOS 17 map camera
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Sheets
    @State private var showSightingSheet = false
    @State private var showHVASheet = false
    @State private var showRouteSheet = false

    // Inputs for your SightingPinInformationView
    @State private var waypointObj: Waypoint? = nil
    @State private var sightingObj: Sighting? = nil
    @State private var hotspotObj: Hotspot? = nil

    // RouteViewModel stuff
    @EnvironmentObject private var routeVM: RouteViewModel

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
                        Button { 
                            Task {
                                await vm.loadSightings()
                            }
                        } label: { 
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(vm.isLoading ? .orange : .primary)
                        }
                        .buttonStyle(.bordered)
                        .disabled(vm.isLoading)
                    }
                    .padding(.horizontal)

                    Button {
                        showRouteSheet = true
                        
                        Task {
                            await routeVM.buildRoute(from: Array(vm.selectedWaypoints))
                        }
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
        .onAppear {
            // Load real data instead of mock
            Task {
                await vm.loadSightings()
            }
            cameraPosition = .region(vm.mapRegion)
        }
        .sheet(isPresented: $showSightingSheet) {
            if let w = waypointObj, let s = sightingObj {
                SightingPinInformationView(sighting: s, origin: .map, waypointObj: w)
                    .presentationBackground(.regularMaterial)
            }
        }
        .sheet(isPresented: $showHVASheet) {
            /*if let w = waypointObj {
                HVAPinInformationView(hotspotObj: w)
                    .presentationBackground(.regularMaterial)
            }*/
        }
        .sheet(isPresented: $showRouteSheet) {
            RouteStackView(waypoints: Array(vm.selectedWaypoints))
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if vm.isLoading {
                VStack {
                    ProgressView("Loading sightings...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if vm.showSightings {
                ForEach(vm.filteredSightings) { s in
                    Annotation("\(s.species.emoji) \(s.species.name)", coordinate: s.coordinate) {
                        PinButton(icon: "mappin.circle.fill", color: .green) {
                            showSightingSheet = true
                            waypointObj = .sighting(s)
                            sightingObj = s
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
                            showHVASheet = true
                            waypointObj = .hotspot(h)
                            hotspotObj = h
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