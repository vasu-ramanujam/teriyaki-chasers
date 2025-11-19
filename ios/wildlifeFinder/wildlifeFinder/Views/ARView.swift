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

extension simd_float4 {
    var xyz: simd_float3 { simd_make_float3(self.x, self.y, self.z) }
}

extension CLLocationCoordinate2D {
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let fromLat = latitude.degreesToRadians
        let fromLon = longitude.degreesToRadians
        let toLat = destination.latitude.degreesToRadians
        let toLon = destination.longitude.degreesToRadians
        
        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)
        return atan2(y, x).radiansToDegrees // degrees from true north
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}

// MARK: - AR Waypoint Component
struct WaypointComponent: Component {
    var waypoint: Waypoint
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
    @State var waypointAnchors: [String: AnchorEntity] = [:]
    
    func withinRange(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, threshold: Double = 3) -> Bool {
        let loc1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let loc2 = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return loc1.distance(from: loc2) <= threshold
    }
    
    func addAnchors(to session: ARSession, in arView: ARView) {
        for waypoint in waypoints {
            let geoAnchor = ARGeoAnchor(coordinate: waypoint.coordinate)
            session.add(anchor: geoAnchor)

            let anchorEntity = AnchorEntity(anchor: geoAnchor)

            // Sphere marker
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.25))
            sphere.position = [0, 0.7, 0]
            // sphere.generateCollisionShapes(recursive: true)
            sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            sphere.components.set(WaypointComponent(waypoint: waypoint))
            sphere.name = waypoint.title

            // Floating text label
            let textMesh = MeshResource.generateText(
                waypoint.title,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.05)
            )
            let textEntity = ModelEntity(mesh: textMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
            textEntity.position = [0, 0.9, 0]
            // textEntity.generateCollisionShapes(recursive: true)

            anchorEntity.addChild(textEntity)
            anchorEntity.addChild(sphere)

            // Save to property instead of local variable
            waypointAnchors[waypoint.id] = anchorEntity

            sphere.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.25)]))
            textEntity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.2, 0.1, 0.01])]))
            arView.scene.addAnchor(anchorEntity)
        }
    }

        
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        func convertToARCoordinates(from coord: CLLocationCoordinate2D, relativeTo origin: CLLocationCoordinate2D) -> SIMD3<Float> {
            let earthRadius: Double = 6378137 // meters
            let deltaLat = coord.latitude - origin.latitude
            let deltaLon = coord.longitude - origin.longitude
            
            let x = deltaLon.degreesToRadians * earthRadius * cos(origin.latitude.degreesToRadians)
            let z = deltaLat.degreesToRadians * earthRadius
            let y: Float = 0.7 // assume flat, AR vertical is y
            
            return SIMD3<Float>(Float(x), y, Float(z))
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {
//            // Remove anchors for waypoints that were removed
//            let existingIDs = Set(waypointAnchors.keys)
//            let currentIDs = Set(waypoints.map { $0.id })
//            
//            let removedIDs = existingIDs.subtracting(currentIDs)
//            
//            for removedID in removedIDs {
//                if let waypoint = waypoints.first(where: { $0.id == removedID }) {
//                    context.coordinator.removeAnchor(for: waypoint)
//                }
//            }
        }
        
        // MARK: - Main ARView Setup
        func makeUIView(context: Context) -> ARView {
            let arView = SharedARView.instance
            context.coordinator.arView = arView
            arView.session.delegate = context.coordinator
            
            // Handle unsupported devices
            if useGeoAnchors && !ARGeoTrackingConfiguration.isSupported {
                print("AR GeoTracking not supported.")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
            }
            
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

            // Install tap gesture only once
            if arView.gestureRecognizers?.isEmpty ?? true {
                let tap = UITapGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleTap(_:))
                )
                arView.addGestureRecognizer(tap)
            }
            
            // Subscribe to scene updates
            context.coordinator.updateCancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                guard let currentWaypoint = self.currentWaypoint else { return }

                // Spawn breadcrumbs only if we haven't already for this waypoint
//                if currentWaypoint.id != context.coordinator.lastBreadcrumbWaypointID {
//                    context.coordinator.lastBreadcrumbWaypointID = currentWaypoint.id
//                    if let polyline = self.routePolyline {
//                        context.coordinator.spawnBreadcrumbs(along: polyline, relativeTo: self.origin)
//                    }
//                }

                // Update arrow rotation relative to the current waypoint
                let deviceLocation = LocationManagerViewModel.shared.coordinate
                let targetLocation = currentWaypoint.coordinate
                let bearingToTarget = deviceLocation.bearing(to: targetLocation)
                if let heading = LocationManagerViewModel.shared.heading {
                    let relativeAngle = bearingToTarget - heading
                    DispatchQueue.main.async {
                        self.arrowRotation = relativeAngle
                    }
                }

                // Trigger waypoint reached callback if within threshold
                if self.withinRange(deviceLocation, targetLocation) {
                    DispatchQueue.main.async {
                        self.onReachedWaypoint?(currentWaypoint)
                    }
                }
            }
            
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
    @State private var debugMessage = "Starting..."
    @State private var showDirections = false
    var routePolyline: MKPolyline?
    
    var body: some View {
        ZStack {
            ARViewContainer(
                waypoints: Binding(
                    get: { vm.selectedWaypoints },
                    set: { vm.selectedWaypoints = $0 }
                ),
                routePolyline: routePolyline,
                onReachedWaypoint: { waypoint in
                    reachedWaypoint = waypoint
                    showPopup = true
                    vm.selectedWaypoints.removeAll { $0.id == waypoint.id }
                },
                
                // uncomment to print debug messages
                onTrackingStatusChanged: { msg in
                    trackingMessage = msg
                },
                onAnchorsPlaced: {
                    anchorsPlaced = true
                },
                onDebugMessage: { msg in
                    debugMessage = msg
                },
                selectedWaypoint: $selectedWaypoint,
                currentWaypoint: $currentWaypoint,
                arrowRotation: $arrowRotation,
                anchorsPlaced: $anchorsPlaced
            )
            // uncomment to print debug messages
            .overlay(
                VStack {
                    Text(debugMessage)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 50)
                    Spacer()
                }
            )
            .onAppear {
                if currentWaypoint == nil {
                    currentWaypoint = vm.selectedWaypoints.first
                }
            }
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(true)
            
            VStack {
                // Top header
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.gray).opacity(1))
                            .shadow(radius: 5)
                            .frame(height: 60)
                        Text("AR Mode")
                    }
                    
                    Button("Switch to Map Mode") {
                        showDirections = true
                    }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 90)
                
                Spacer()
                
                if !anchorsPlaced {
                    VStack {
                        Text(trackingMessage)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                        
                        Spacer()
                    }
                    .transition(.opacity)
                }
                
                
                // Popup overlay
                if showPopup, self.toggleDismiss {
                    VStack(spacing: 12) {
                        if let waypoint = reachedWaypoint {
                            Text("✅ Reached \(waypoint.title)")
                                .font(.headline)
                        }
                        
                        if let waypoint = reachedWaypoint,
                           let currentIndex = vm.selectedWaypoints.firstIndex(of: waypoint),
                           currentIndex + 1 < vm.selectedWaypoints.count {
                            Button("Next Waypoint") {
                                self.currentWaypoint = vm.selectedWaypoints[currentIndex + 1]
                                vm.selectedWaypoints.removeFirst()
                                reachedWaypoint = nil
                                showPopup = false
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else {
                            Text("🎉 Route completed!")
                                .font(.headline)
                        }
                        
                        Button("Dismiss") {
                            reachedWaypoint = nil
                            showPopup = false
                            self.toggleDismiss = false
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground).opacity(0.95))
                            .shadow(radius: 5)
                    )
                    .padding(.bottom, 72)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showPopup)
                } else {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(.black)
                                .opacity(0.75)
                                .frame(width: 125, height: 125)
                                .padding(.bottom, 40)
                            
                            Image(systemName: "location.north.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(arrowRotation))
                                .padding(.bottom, 40)
                        }
                        
                        Button("End Route") { dismiss() }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 96)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(item: $selectedWaypoint) { waypoint in
            switch waypoint {
            case .sighting(let sighting):
                SightingPinInformationView(
                    sighting: sighting,
                    origin: .map,
                    waypointObj: waypoint
                )
            case .hotspot(let hotspot):
                Text("Hotspot: \(hotspot.name)")
            }
        }
        .navigationDestination(isPresented: $showDirections) {
            DirectionsView()
        }
    }
}

