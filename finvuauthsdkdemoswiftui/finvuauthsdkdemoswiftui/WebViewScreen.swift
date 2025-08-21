//
//  WebViewScreen.swift
//  finvuauthsdkdemoswiftui
//
//  Created by Pranad Waghmare on 21/08/25.
//

import SwiftUI
import WebKit
import FinvuAuthenticationSDK

struct WebViewScreen: View {
    @StateObject private var webViewStore = WebViewStore()

    var body: some View {
        WebView(webView: webViewStore.webView)
            .onAppear {
                if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })?.rootViewController {
                    FinvuAuthenticationWrapper.shared.setupWebView(
                        webViewStore.webView,
                        viewController: rootVC,
                        environment: .development
                    )
                }
                if let url = URL(string: Constants.webViewBaseURL) {
                    webViewStore.webView.load(URLRequest(url: url))
                }
            }
            .onDisappear {
                FinvuAuthenticationWrapper.shared.cleanupAll()
            }
            .edgesIgnoringSafeArea(.all)
    }
}
