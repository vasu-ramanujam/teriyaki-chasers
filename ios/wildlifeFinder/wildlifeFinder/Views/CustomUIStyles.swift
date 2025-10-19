//
//  CustomUIStyles.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/9/25.
//

import SwiftUI

let ui_orange = Color(red: 241/255, green: 154/255, blue: 62/255)
let ui_green = Color(red: 36/255, green: 86/255, blue: 61/255)



struct OrangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        let label = configuration.label
        HStack{
            label
        }
        .font(.system(size: 24, design: .rounded))
        .foregroundColor(.black)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .foregroundColor(ui_orange)
            
        }
    }
}

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        let label = configuration.label
        HStack{
            label
        }
        .font(.system(size: 14, design: .rounded))
        .foregroundColor(.white)
        .padding(7)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(ui_green)
            
        }
    }
}

