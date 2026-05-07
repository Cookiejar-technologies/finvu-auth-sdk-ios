import SwiftUI
import WebKit
import FinvuAuthenticationSDK

struct WebViewScreen: View {
    @StateObject private var webViewStore = WebViewStore()
    @State private var showLogs = false
    let customURLString: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                    if let url = URL(string: customURLString) {
                        webViewStore.webView.load(URLRequest(url: url))
                    }
                }
                .onDisappear {
                    FinvuAuthenticationWrapper.shared.cleanupAll()
                }

            Button {
                showLogs = true
            } label: {
                Text("JS Logs (\(webViewStore.consoleLogs.logs.count))")
                    .font(.system(.footnote, design: .monospaced))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
        .navigationTitle("Finvu Auth SDK Demo App")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogs) {
            LogsSheet(store: webViewStore.consoleLogs)
        }
    }
}

private struct LogsSheet: View {
    @ObservedObject var store: ConsoleLogStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                if store.logs.isEmpty {
                    Text("No logs yet.")
                        .foregroundColor(.gray)
                        .padding(32)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(store.logs.enumerated()), id: \.offset) { _, log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.4))
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
            .background(Color(red: 0.12, green: 0.12, blue: 0.12).ignoresSafeArea())
            .navigationTitle("JS Console (\(store.logs.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.12, green: 0.12, blue: 0.12), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { store.clear() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
