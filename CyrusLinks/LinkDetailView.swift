//
//  LinkDetailView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct LinkDetailView: View {
    let link: AppLink;
    
    var body: some View {
        if link.lyrics.isEmpty {
            SwiftUIWebView(url: URL(string: link.url)).navigationTitle(link.name)
        } else {
            ScrollView {
                Text(link.lyrics)
                    .padding()
            }.navigationTitle(link.name)
        }
    }
}

//struct LinkDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LinkDetailView()
//    }
//}
