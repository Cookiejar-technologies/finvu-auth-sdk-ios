import SwiftUI
import WebKit
import FinvuAuthenticationSDK

/// Persists `console.log/info/warn/error/debug` messages captured from the WebView
/// for the duration of a single WebView session. Survives modal close/reopen.
final class ConsoleLogStore: ObservableObject {
    @Published var logs: [String] = []

    func append(_ entry: String) {
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}

/// Holds the WKWebView instance and wires up console-message capture so the
/// JS Logs sheet on the WebView screen can display in-page console output.
final class WebViewStore: ObservableObject {
    let webView: WKWebView
    let consoleLogs = ConsoleLogStore()

    init() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        let consoleScript = """
        (function() {
          const levels = ['log', 'info', 'warn', 'error', 'debug'];
          levels.forEach(level => {
            const original = console[level];
            console[level] = function(...args) {
              try {
                const formatted = args.map(a => {
                  if (a instanceof Error) return a.stack || a.message;
                  if (typeof a === 'object') {
                    try { return JSON.stringify(a); } catch (e) { return String(a); }
                  }
                  return String(a);
                }).join(' ');
                window.webkit.messageHandlers.consoleHandler.postMessage('[' + level.toUpperCase() + '] ' + formatted);
              } catch (e) {}
              return original.apply(console, args);
            };
          });
          window.addEventListener('error', function(e) {
            try {
              window.webkit.messageHandlers.consoleHandler.postMessage('[ERROR] ' + (e.message || e.error || 'Unknown error'));
            } catch (err) {}
          });
        })();
        """
        let userScript = WKUserScript(source: consoleScript,
                                      injectionTime: .atDocumentStart,
                                      forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        let handler = ConsoleMessageHandler(store: consoleLogs)
        userContentController.add(handler, name: "consoleHandler")

        self.webView = WKWebView(frame: .zero, configuration: config)
    }
}

private final class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    let store: ConsoleLogStore
    init(store: ConsoleLogStore) { self.store = store }

    func userContentController(_ uc: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if let text = message.body as? String {
            store.append(text)
        }
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
