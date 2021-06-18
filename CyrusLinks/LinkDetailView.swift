//
//  LinkDetailView.swift
//  CyrusLinks
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI

struct LinkDetailView: View {
    var body: some View {
        SwiftUIWebView(url: URL(string: "https://spreadsheets.google.com/feeds/cells/1JfkF-N492ygBLMcHQhXUFl-MtlMGQz35Vco4caiVw9c/1/public/full?alt=json"))
    }
}

struct LinkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LinkDetailView()
    }
}
