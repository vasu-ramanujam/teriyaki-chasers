//
//  ARViewContainer.swift
//  wildlifeFinder
//
//  Created by Alvin Jiang on 11/19/25.
//

import SwiftUICore
import SwiftUI

// MARK: - Subviews

struct ARHeaderView: View {
    let onSwitchToMap: () -> Void
    
    var body: some View {
        HStack {
            Label("AR Mode", systemImage: "camera.viewfinder")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.regularMaterial)
                .cornerRadius(12)
            
            Button(action: onSwitchToMap) {
                Text("Switch to Map")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

struct StatusMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
            .transition(.opacity)
    }
}

struct NavigationHUDView: View {
    let arrowRotation: Double
    let hasCurrentWaypoint: Bool
    let onSkip: () -> Void
    let onEndRoute: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            // Direction Arrow
            ZStack {
                Circle()
                    .fill(.black.opacity(0.75))
                    .frame(width: 125, height: 125)
                
                Image(systemName: "location.north.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(arrowRotation))
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Controls
            HStack(spacing: 20) {
                if hasCurrentWaypoint {
                    Button("Skip Waypoint", action: onSkip)
                        .tint(.orange)
                        .buttonStyle(.borderedProminent)
                }
                
                Button("End Route", action: onEndRoute)
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 96)
        }
    }
}

struct WaypointArrivalPopup: View {
    let waypoint: Waypoint
    let isLastWaypoint: Bool
    let onNext: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("✅ Reached \(waypoint.title)")
                .font(.headline)
            
            if !isLastWaypoint {
                Button("Next Waypoint", action: onNext)
                    .buttonStyle(.borderedProminent)
            } else {
                Text("🎉 Route completed!")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.95))
                .shadow(radius: 10)
        )
        .padding(.bottom, 72)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
