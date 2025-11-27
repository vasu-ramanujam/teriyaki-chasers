//
//  ARView.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 10/22/25.
//

import SwiftUI
import UIKit
import RealityKit
import ARKit
import MapKit
import Photos
import Combine
import CoreLocation


final class SharedARView {
    static let instance: ARView = {
        let view = ARView(frame: .zero)
        return view
    }()
}


// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    @Binding var waypoints: [Waypoint]
    var window: UIWindow?
    var useGeoAnchors: Bool = true
    let origin = LocationManagerViewModel.shared.coordinate
    var routePolyline: MKPolyline? = nil
    
    var onError: ((String) -> Void)? = nil
    var onReachedWaypoint: ((Waypoint) -> Void)? = nil
    
    // vars used to show debug messages on phone
    var onTrackingStatusChanged: ((String) -> Void)? = nil
    var onAnchorsPlaced: (() -> Void)? = nil
     var onDebugMessage: ((String) -> Void)? = nil
    // private var debugOn: Bool = false
    
    // Selected waypoint is for determining which info card to display
    // Current is for the current waypoint user is navigating to
    @Binding var selectedWaypoint: Waypoint?
    @Binding var currentWaypoint: Waypoint?
    @Binding var arrowRotation: Double
    @Binding var anchorsPlaced: Bool
    
    
    // TODO: consolidate withinRange function into one file
    func withinRange(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, threshold: Double = 3) -> Bool {
        let loc1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let loc2 = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return loc1.distance(from: loc2) <= threshold
    }
    
        
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    
    // MARK: - updateUIView
    func updateUIView(_ uiView: ARView, context: Context) {
        // Only sync if we have already localized and placed initial anchors or binding vars changes
        if context.coordinator.anchorsAdded {
            context.coordinator.syncWaypoints()
        }
        
        // adds breadcrumbs that guides users to the next waypoint
        if let polyline = routePolyline,
           context.coordinator.anchorsAdded,
           context.coordinator.breadcrumbAnchorEntity == nil {
            context.coordinator.spawnBreadcrumbs(along: polyline)
        }
        
        // Cleanup if polyline is removed
        if routePolyline == nil && context.coordinator.breadcrumbAnchorEntity != nil {
            context.coordinator.removeBreadcrumbs()
        }
    }
    
    
    // MARK: - Main ARView Setup
    func makeUIView(context: Context) -> ARView {
        let arView = SharedARView.instance
        
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator
        
        // remove old gestures that were linked to previous coordinator
        arView.gestureRecognizers?.removeAll()
        let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)
        
        // Run AR config ONLY once
        if arView.session.configuration == nil {
            // Handle unsupported devices
            if useGeoAnchors && !ARGeoTrackingConfiguration.isSupported {
                print("AR GeoTracking not supported.")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
            }

            let configuration = ARGeoTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            arView.session.run(configuration)
        }
        
        // Subscribe to multiple scene updates (arrow dir, distance)
        context.coordinator.monitorScene()
        return arView
    }
}
    
    
// MARK: - ARView Screen
struct ARViewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SightingMapViewModel.self) private var vm
    
    @State private var selectedWaypoint: Waypoint? = nil
    @State private var currentWaypoint: Waypoint? = nil
    @State private var reachedWaypoint: Waypoint? = nil
    @State private var showPopup: Bool = false
    @State private var toggleDismiss: Bool = true
    @State private var arrowRotation: Double = 0.0
    @State private var trackingMessage: String = "Initializing AR…"
    @State private var anchorsPlaced: Bool = false
    // @State private var debugMessage = "Starting..."
    @State private var showDirections = false
    
    var routePolyline: MKPolyline?
    
    var body: some View {
        ZStack {
            arLayer
            // uncomment to print debug messages
//            .overlay(
//                VStack {
//                    Text(debugMessage)
//                        .padding()
//                        .background(Color.black.opacity(0.7))
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                        .padding(.top, 50)
//                    Spacer()
//                }
//            )
            VStack {
                if !anchorsPlaced {
                    Spacer().frame(height: 100)
                    StatusMessageView(message: trackingMessage)
                    Spacer()
                } else {
                    NavigationHUDView(
                        arrowRotation: arrowRotation,
                        hasCurrentWaypoint: currentWaypoint != nil,
                        onSkip: skipCurrentWaypoint,
                        onEndRoute: { dismiss() }
                    )
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            if showPopup, let waypoint = reachedWaypoint {
                WaypointArrivalPopup(
                    waypoint: waypoint,
                    isLastWaypoint: vm.selectedWaypoints.last?.id == waypoint.id,
                    onNext: advanceToNextWaypoint,
                    onDismiss: dismissPopup
                )
            }
        }
        .overlay(alignment: .top) {
                ARHeaderView(onSwitchToMap: { showDirections = true })
        }
        .onAppear(perform: setupInitialState)
                .sheet(item: $selectedWaypoint, content: waypointSheetContent)
                .navigationDestination(isPresented: $showDirections) { DirectionsView() }
    }
}


// MARK: - Components for ARViewScreen
private extension ARViewScreen {
    
    var arLayer: some View {
        ARViewContainer(
            waypoints: Binding(get: { vm.selectedWaypoints }, set: { vm.selectedWaypoints = $0 }),
            routePolyline: routePolyline,
            onReachedWaypoint: { waypoint in
                reachedWaypoint = waypoint
                showPopup = true
            },
            onTrackingStatusChanged: { msg in trackingMessage = msg },
            onAnchorsPlaced: { anchorsPlaced = true },
            selectedWaypoint: $selectedWaypoint,
            currentWaypoint: $currentWaypoint,
            arrowRotation: $arrowRotation,
            anchorsPlaced: $anchorsPlaced
        )
        .edgesIgnoringSafeArea(.all)
    }

    
    func setupInitialState() {
        if currentWaypoint == nil {
            currentWaypoint = vm.selectedWaypoints.first
        }
    }
    
    
    func skipCurrentWaypoint() {
        guard let current = currentWaypoint,
              let index = vm.selectedWaypoints.firstIndex(of: current) else { return }
        
        vm.selectedWaypoints.remove(at: index)
        updateCurrentWaypoint(from: index)
    }
    
    
    func advanceToNextWaypoint() {
        guard let reached = reachedWaypoint,
              let index = vm.selectedWaypoints.firstIndex(of: reached) else { return }
        
        vm.selectedWaypoints.remove(at: index)
        updateCurrentWaypoint(from: index)
        
        reachedWaypoint = nil
        showPopup = false
    }
    
    
    func dismissPopup() {
        // If we just dismissed, remove the reached point from list
        if let reached = reachedWaypoint, let index = vm.selectedWaypoints.firstIndex(of: reached) {
             vm.selectedWaypoints.remove(at: index)
             updateCurrentWaypoint(from: index)
        }
        reachedWaypoint = nil
        showPopup = false
    }
    
    
    func updateCurrentWaypoint(from index: Int) {
        if index < vm.selectedWaypoints.count {
            self.currentWaypoint = vm.selectedWaypoints[index]
        } else {
            self.currentWaypoint = nil
        }
    }
    
    
    @ViewBuilder
    func waypointSheetContent(_ waypoint: Waypoint) -> some View {
        switch waypoint {
        case .sighting(let sighting):
            SightingPinInformationView(sighting: sighting, origin: .map, waypointObj: waypoint)
        case .hotspot(let hotspot):
            Text("Hotspot: \(hotspot.name)")
        }
    }
}
