# Finvu Auth SDK — iOS

**Version:** `1.0.4` · **iOS:** 16.0+ · **Swift:** 5.0+ · **Xcode:** 14+

Silent Network Authentication (SNA) SDK for iOS, with WKWebView bridge support for web-based authentication flows.

---

## Installation

Add to your `Podfile`:

```ruby
platform :ios, '16.0'

pod 'FinvuAuthenticationSDK', :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git', :tag => '1.0.4'
```

Then run:

```bash
pod install --repo-update
```

---

## iOS Setup

### Info.plist — Network Security

Add the following to your `Info.plist` to allow SNA carrier HTTP calls:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>80.in.safr.sekuramobile.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
            <key>NSIncludesSubdomains</key><true/>
        </dict>
        <key>api-csp.airtel.in</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
            <key>NSIncludesSubdomains</key><true/>
        </dict>
        <key>in-vil.ipification.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
            <key>NSIncludesSubdomains</key><true/>
        </dict>
        <key>partnerapi.jio.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
            <key>NSIncludesSubdomains</key><true/>
        </dict>
    </dict>
</dict>
```

---

## Integration

### Option A — WebView App

Use this if your app loads a web page inside a `WKWebView` and the web app drives the authentication flow.

```swift
import FinvuAuthenticationSDK

class AuthViewController: UIViewController {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the SDK bridge — call once after webView is ready
        FinvuAuthenticationWrapper.shared.setupWebView(
            webView,
            viewController: self,
            environment: .production  // or .development
        )

        webView.load(URLRequest(url: URL(string: "https://your-web-app-url")!))
    }

    deinit {
        FinvuAuthenticationWrapper.shared.cleanupAll()
    }
}
```

**SwiftUI:**

```swift
import FinvuAuthenticationSDK
import SwiftUI
import WebKit

struct AuthWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        FinvuAuthenticationWrapper.shared.setupWebView(
            webView,
            viewController: getRootViewController(),
            environment: .production
        )
        webView.load(URLRequest(url: URL(string: "https://your-web-app-url")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

Your web app communicates with the SDK through the `finvu_authentication_bridge` JS bridge.

---

### Option B — Native App

Use this if your app handles the authentication flow entirely in Swift, without a WebView.

```swift
import FinvuAuthenticationSDK

// 1. Setup — call once
FinvuAuthenticationNativeWrapper.shared.setup(
    viewController: self,
    environment: .production  // or .development
)

// 2. Init — call with requestId from your backend
FinvuAuthenticationNativeWrapper.shared.initAuth(
    config: ["requestId": "YOUR_REQUEST_ID"]
) { result in
    switch result {
    case .success(let response):
        // proceed to startAuth
        break
    case .failure(let error):
        // handle error
        break
    }
}

// 3. Start SNA — call with the SNA URL returned by your backend
FinvuAuthenticationNativeWrapper.shared.startAuth(snaUrl: "SNA_URL") { result in
    switch result {
    case .success(let response):
        let token = response.token  // auth complete — use token
    case .failure(let error):
        // handle error
    }
}

// 4. Cleanup — call when done or user exits
FinvuAuthenticationNativeWrapper.shared.cleanupAll()
```

---

## Demo App

See [`finvuauthsdkdemoswiftui/`](./finvuauthsdkdemoswiftui) for a complete working example.


---

## Support

support@cookiejar.co.in · [finvu.in](https://finvu.in)
