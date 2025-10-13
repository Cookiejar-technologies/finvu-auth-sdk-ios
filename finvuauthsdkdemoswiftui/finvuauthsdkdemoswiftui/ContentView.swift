//
//  ContentView.swift
//  finvuauthsdkdemoswiftui
//
//  Created by Pranad Waghmare on 28/07/25.
//

import SwiftUI
import FinvuAuthenticationSDK

struct HomeView: View {
	@State private var customURL: String = "https://test-web-app-8a50c.web.app"
	var body: some View {
		NavigationView {
			VStack(spacing: 20) {
				TextField("Enter URL", text: $customURL)
					.keyboardType(.URL)
					.autocapitalization(.none)
					.disableAutocorrection(true)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.padding(.horizontal)
				NavigationLink("Load WebView", destination: WebViewScreen(customURLString: customURL))
					.padding()
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(10)
					.disabled(customURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

				NavigationLink("Load Native View", destination: NativeAuthView())
					.padding()
					.background(Color.green)
					.foregroundColor(.white)
					.cornerRadius(10)
					.disabled(customURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
			.navigationTitle("Finvu Auth Demo")
		}
	}
}

#Preview {
	HomeView()
}
