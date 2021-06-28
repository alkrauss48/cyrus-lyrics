//
//  SpotifyButton.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/27/21.
//

import SwiftUI

struct SpotifyButton: View {
    let url: String
    
    var body: some View {
        Button(action: {
            UIApplication.shared.open(URL(string: url)!)
        }) {
            HStack(spacing: 2.0) {
                Text("Open in Spotify")
                Spacer()
                Image(systemName: "arrow.forward")
            }.foregroundColor(Color.white)
            .padding(.vertical, 8.0)
            .frame(maxWidth: .infinity)
            .padding(/*@START_MENU_TOKEN@*/.horizontal/*@END_MENU_TOKEN@*/)
            
                
        }
        .background(Color(red: 37 / 255, green: 211 / 255, blue: 78 / 255))
    }
}

struct SpotifyButton_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyButton(url: "foo")
    }
}
