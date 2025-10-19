//
//  RoutePreviewView.swift
//  wildlifeFinder
//
//  Created by Vasu Ramanujam on 10/15/25.
//

import SwiftUI


struct pin_in_route: Identifiable {
    var title: String
    var time: Int
    let id = UUID()
}


struct RoutePreviewView: View {
    
    @Binding var inCurrentRoute: Bool
    @State var route_pins: [pin_in_route] = [
        pin_in_route(title: "Pin A", time: 2 ),
        pin_in_route(title: "Pin B", time: 3 ),
        pin_in_route(title: "Pin C", time: 3 )
    ]
    
    
    @ViewBuilder
    func display_when_route() -> some View {
        VStack{
            Text("Displaying Route...")
                .font(.title)
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: 300, height: 300)
            Text("Insert map here")
            
            List{
                ForEach(route_pins){pin in
                    HStack{
                        Text(pin.title)
                        Spacer()
                        Text(String(pin.time) + " min")
                        //Text(pin.time)
                    }
                }
            }
            
            Button("Go"){
                //do something
            }
            .buttonStyle(OrangeButtonStyle())
        }
    }
    
    
    @ViewBuilder
    func guard_no_route() -> some View {
        if inCurrentRoute{
            display_when_route()
        } else {
            Text("No Current Route! \n Generate a route to do whatever")
        }
    }
    var body: some View {
        guard_no_route()
    }
}
