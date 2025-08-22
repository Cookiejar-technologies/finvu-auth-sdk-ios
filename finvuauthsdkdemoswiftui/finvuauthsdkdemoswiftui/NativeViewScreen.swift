//
//  NativeViewScreen.swift
//  finvuauthsdkdemoswiftui
//
//  Created by Pranad Waghmare on 21/08/25.
//

import Foundation
import FinvuAuthenticationSDK
import SwiftUI

struct NativeAuthView: View {
    @State private var phoneNumber = ""
    @State private var authResult: String = ""

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            TextField("Enter Mobile Number", text: $phoneNumber)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

            Button("Init Auth")
            {
                callInitAuth()
            }
            .buttonStyle(.borderedProminent)

            Button("Start Auth") {
                callStartAuth()
            }
            .buttonStyle(.borderedProminent)

            Text("Finvu auth sdk response:")
                .fontWeight(.semibold)
                .padding(.top)

            Text(authResult)
                .foregroundColor(.black)  // <-- Set text color explicitly to white
                .padding()
                .font(.footnote)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Back") {
                FinvuAuthenticationNativeWrapper.shared.cleanupAll()
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .navigationTitle("Native Auth")
        .onAppear {
            // Setup native SDK
            if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController {
                    FinvuAuthenticationNativeWrapper.shared.setup(viewController: rootVC, environment: .development)
            }
        }
    }

    private func callInitAuth() {
        let config: [String: Any] = [
            "appId": Constants.Config.appId,
            "requestId": Constants.Config.requestId
        ]
        authResult = "Processing ..."
        FinvuAuthenticationNativeWrapper.shared.initAuth(config: config) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    authResult = "InitAuth Success: \(response)"
                case .failure(let error):
                    authResult = "InitAuth Error: \(error)"
                }
            }
        }
    }

    private func callStartAuth() {
        authResult = "Processing ..."
        FinvuAuthenticationNativeWrapper.shared.startAuth(phoneNumber: phoneNumber) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    authResult = "StartAuth Success: \(response)"
                case .failure(let error):
                    authResult = "StartAuth Error: \(error)"
                }
            }
        }
    }
}
