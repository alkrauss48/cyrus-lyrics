//
//  CategoryList.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/18/22.
//

import SwiftUI

struct HowItWorksView: View {
    let items: [FAQItem] = FAQItem.items
    @Environment(\.openURL) var openURL
    @StateObject var stateManager = StateManager.Get()

    var body: some View {
        NavigationView {
            VStack{
                List(items, children: \.items) { row in
                    Text(row.name)
                        
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
                            .background(Color("Primary"))
                            .cornerRadius(40)
                    }
                }.padding()
                
            }
            .navigationTitle("How It Works")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stateManager.toggleMenu()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
        }
    }
}

struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        HowItWorksView()
    }
}
