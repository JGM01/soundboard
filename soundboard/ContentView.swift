//
//  ContentView.swift
//  soundboard
//
//  Created by Jacob Germana-McCray on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    let items = Array(1...12)
    
    private let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
    
    var body: some View {
        VStack {
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
