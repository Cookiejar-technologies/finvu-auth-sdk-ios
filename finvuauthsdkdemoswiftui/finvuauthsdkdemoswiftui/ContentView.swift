//
//  ContentView.swift
//  finvuauthsdkdemoswiftui
//
//  Created by Pranad Waghmare on 28/07/25.
//

import SwiftUI
import WebKit
import FinvuAuthenticationSDK

struct ContentView: View {
    @StateObject private var webViewStore = WebViewStore()

    var body: some View {
        WebView(webView: webViewStore.webView)
            .onAppear {
                // Get the root view controller to pass to the SDK
                if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })?.rootViewController {
                    FinvuAuthenticationWrapper.shared.setupWebView(webViewStore.webView, viewController: rootVC,environment: .development)
                }
            }
            .edgesIgnoringSafeArea(.all)
    }
}

// Helper class to keep WKWebView alive
final class WebViewStore: ObservableObject {
    @Published var webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
    }
}

// UIViewRepresentable wrapper for WKWebView
struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        // Optionally load a URL or local HTML file
        if let url = URL(string: "https://test-web-app-8a50c.web.app") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    ContentView()
}

