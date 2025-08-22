//
//  ContentView.swift
//  finvuauthsdkdemoswiftui
//
//  Created by Pranad Waghmare on 28/07/25.
//

import SwiftUI
import FinvuAuthenticationSDK

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink("Load WebView", destination: WebViewScreen())
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                NavigationLink("Load Native View", destination: NativeAuthView())
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .navigationTitle("Finvu Auth Demo")
        }
    }
}

#Preview {
    HomeView()
}
