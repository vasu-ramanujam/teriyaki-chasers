//
//  CustomTabBar.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/8/25.
//

// Adapted from https://youtu.be/V_d2CgxRLIA?si=dwFWIMXQ3yijiFgx

// This file should create a custom tab bar that matches our UI Figma prototype:
// importantly, with a large plus icon at the center

import SwiftUI

struct TabBarButton: View {
    let systemImageName: String
    let title: String
    let action: () -> Void
    
    var body: some View{
        Button(action: action) {
            VStack {
                Image(systemName: systemImageName)
                    .foregroundColor(.white)
                    .padding([.leading, .trailing])
                    .padding(.bottom, 5)
                    .font(.system(size: 28))
                Text(title)
                    .foregroundStyle(Color.white)
                    .padding(.bottom)
                    .font(.system(size: 9))
            }
        }
    }
    
}

struct BottomTabBarView: View {
    @Binding var selectedTab: Int //or enum Tab
    
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(Color(red: 36/255, green: 86/255, blue: 61/255))
            
            HStack (alignment: .bottom) {

                TabBarButton(systemImageName: "map", title: "Sighting Map") { selectedTab = 0 }
                    .offset(y: -5)
                TabBarButton(systemImageName: "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill", title: "Current Route") { selectedTab = 1 }
                    .offset(y: -5)

                Circle()
                .fill(ui_green)
                .stroke(.white, lineWidth: 1)
                .frame(height: 80)
                .offset(y: -10)
                .overlay(alignment: .top) {
                    Button {
                        selectedTab = 2
                    } label: {
                        VStack {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 40))
                                .padding()
                            //Text("Add")
                        }
                    }
                        .offset(y: -5)
                }
                
                TabBarButton(systemImageName: "magnifyingglass", title: "Animal Search") { selectedTab = 3 }
                    .offset(y: -5)
                TabBarButton(systemImageName: "house.fill", title: "User Dashboard") { selectedTab = 4 }
                    .offset(y: -5)

            }
        }
        .frame(height: 90)
    }
}
