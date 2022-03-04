//
//  SpotifyButton.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/27/21.
//

import SwiftUI

struct SpotifyButton: View {
    let url: URL
    
    var body: some View {
        Button(action: {
            UIApplication.shared.open(url)
        }) {
            Text("Open in Spotify")
                .fontWeight(.semibold)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color(red: 37 / 255, green: 211 / 255, blue: 78 / 255))
                .cornerRadius(40)
        }
    }
}

struct SpotifyButton_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyButton(url: URL(string: "foo")!)
    }
}
