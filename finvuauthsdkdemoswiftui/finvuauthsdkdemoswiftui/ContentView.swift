//
//  ContentView.swift
//  finvuauthsdkdemoswiftui
//

import SwiftUI
import FinvuAuthenticationSDK

struct HomeView: View {
    @State private var customURL: String = "https://test-web-app-8a50c.web.app"

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer().frame(height: 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text("WebView URL")
                        .font(.headline)
                        .foregroundColor(.black)
                    TextField("Enter URL", text: $customURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 8)

                NavigationLink(destination: WebViewScreen(customURLString: customURL)) {
                    Text("Load WebView")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .disabled(customURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                NavigationLink(destination: NativeAuthView()) {
                    Text("Load Native View")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("Finvu Auth SDK Demo App")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
}
