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
//        Text(link.url)
        SwiftUIWebView(url: URL(string: link.url))
    }
}

//struct LinkDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LinkDetailView()
//    }
//}
