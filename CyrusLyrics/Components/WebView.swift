//
//  WebView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 6/18/21.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // SwiftUI calls this whenever any state the view depends on changes,
        // so only load when the URL is new.
        guard let url, url != context.coordinator.loadedURL else {
            return
        }

        context.coordinator.loadedURL = url
        webView.load(URLRequest(url: url))
    }

    final class Coordinator {
        var loadedURL: URL?
    }
}

#Preview {
    WebView(url: URL(string: "https://www.google.com/search?q=Wagon+Wheel+lyrics"))
}
