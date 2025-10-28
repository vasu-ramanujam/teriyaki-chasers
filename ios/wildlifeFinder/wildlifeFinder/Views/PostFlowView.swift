//
//  PostFlowView.swift
//  wildlifeFinder
//
//  Created by Owen Davis on 10/28/25.
//
import SwiftUI

struct PostFlowView: View {
    var body: some View {
        NavigationStack {
            InitialViewBigButtons()
        }
    }
}

struct InitialView: View {
    @State var hasImage = false
    @State var hasSound = false

    var body: some View {
        VStack {
            // Display image
            if hasImage {
                Text("Image goes here")
            }
            
            // Add an image
            Button {
                // Hook to taking the picture
                hasImage = true // MOVE THIS TO THE CAMERA PAGE WHEN THAT IS IMPLEMENTED
            } label: {
                Image(systemName: "camera")
                Text(hasImage ? "Retake Photo" : "Take Photo")
            }
            .padding(.bottom)
            
            // Display image
            if hasSound {
                Text("Sound goes here")
            }
            
            // Add a sound
            Button {
                // Hook to recording sound
                hasSound = true // MOVE THIS TO THE CAMERA PAGE WHEN THAT IS IMPLEMENTED
            } label: {
                Image(systemName: "mic")
                Text(hasSound ? "Rerecord Audio" : "Record Audio")
            }
            .padding(.bottom)

            // Identify the sighting
            Button {
                // Hook to Identify page
            } label: {
                Text("Identify")
            }
            .disabled(!(hasImage || hasSound))
            .padding(.bottom)
        }
    }
}

struct InitialViewBigButtons: View {
    @State var hasImage = false
    @State var hasSound = false

    var body: some View {
        VStack {
            // Display image
            if hasImage {
                Text("Image goes here")
            }
            
            // Add an image
            Button {
                // Hook to taking the picture
                hasImage = true // MOVE THIS TO THE CAMERA PAGE WHEN THAT IS IMPLEMENTED
            } label: {
                Image(systemName: "camera")
                    .foregroundStyle(.white)
                Text(hasImage ? "Retake Photo" : "Take Photo")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            // Display image
            if hasSound {
                Text("Sound goes here")
            }
            
            // Add a sound
            Button {
                // Hook to recording sound
                hasSound = true // MOVE THIS TO THE CAMERA PAGE WHEN THAT IS IMPLEMENTED
            } label: {
                Image(systemName: "mic")
                    .foregroundStyle(.white)
                Text(hasSound ? "Rerecord Audio" : "Record Audio")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(
                buttonBackground(color: Color(red: 35/255.0, green: 86/255.0, blue: 61/255.0)),
                alignment: .center
            )
            .padding(.bottom)

            if hasSound || hasImage {
                // Identify the sighting
                Button {
                    // Hook to Identify page
                } label: {
                    Text("Identify")
                        .foregroundStyle(.black)
                }
                .padding()
                .background(
                    buttonBackground(color: Color(red: 241/255.0, green: 154/255.0, blue: 62/255.0)),
                    alignment: .center
                )
            }
        }
        .scaleEffect(1.5)
    }
}

struct buttonBackground: View {
    var color: Color
    var cornerRad = 10.0
    var shadowRad = 5.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRad)
            .fill(color)
            .shadow(radius: shadowRad)
    }
}
