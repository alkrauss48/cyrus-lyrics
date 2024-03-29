//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/18/22.
//

import SwiftUI

struct HowItWorksView: View {
    @Environment(\.openURL) var openURL
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
            VStack{
                List(FAQItem.items, children: \.items) { row in
                    Text(row.name).padding(10)
                }
                HStack {
                    Button(action: {
                        openURL(URL(string: "https://www.youtube.com/playlist?list=PLWXp2X5PBDOmFd1kqyYsPtYwdgXIfDZT3")!)
                    }) {
                        Text("View Tutorials")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(!stateManager.connected ? Color.gray : Color("Primary"))
                            .cornerRadius(40)
                    }
                }.padding()
                    .disabled(!stateManager.connected)
            }.navigationTitle("How It Works")

    }
}

struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        HowItWorksView()
    }
}
