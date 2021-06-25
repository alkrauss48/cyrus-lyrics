//
//  WebView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//
// Code based on: https://www.youtube.com/watch?v=MUVSRV4jXYE&t=312s

import SwiftUI
import WebKit

struct SwiftUIWebView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        
        return WKWebView(frame: .zero, configuration: config)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let myUrl = url else {
            return
        }
        
        let request = URLRequest(url: myUrl)
        uiView.load(request)
    }
}
