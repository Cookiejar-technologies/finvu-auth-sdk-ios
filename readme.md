# FinvuAuthenticationSDK — iOS

iOS 16+ · Swift 5.0+ · Xcode 14+

---

## Installation

**Podfile:**
```ruby
pod 'FinvuAuthenticationSDK', :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git', :tag => '1.0.3'
```


```bash
pod install --repo-update
```

**Info.plist** — add for Silent Network Authentication:
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

There are two ways to integrate depending on your app type.

---

### Option A — WebView App

Use this if your app renders a web app inside a `WKWebView`. The SDK registers a JS bridge that your web app calls directly.

```swift
import FinvuAuthenticationSDK

// Setup — call once after your WKWebView is ready
FinvuAuthenticationWrapper.shared.setupWebView(
    webView,
    viewController: self,        // or rootVC in SwiftUI
    environment: .production
)

// Cleanup — call when the user exits the auth flow
FinvuAuthenticationWrapper.shared.cleanupAll()
```

Your web app communicates with the SDK through the `finvu_authentication_bridge` JS bridge (see separate JS integration guide).

---

### Option B — Native App

Use this if your app handles auth entirely in Swift, without a WebView.

```swift
import FinvuAuthenticationSDK

// 1. Setup
FinvuAuthenticationNativeWrapper.shared.setup(
    viewController: self,
    environment: .production
)

// 2. Init — call with your appId and requestId
FinvuAuthenticationNativeWrapper.shared.initAuth(
    config: ["requestId": "YOUR_REQUEST_ID"]
) { result in
    switch result {
    case .success(let response): // proceed to startAuth
    case .failure(let error):    // handle error
    }
}

// 3. Start SNA — call with the SNA URL returned by your backend
FinvuAuthenticationNativeWrapper.shared.startAuth(snaUrl: "SNA_URL") { result in
    switch result {
    case .success(let response): // auth complete, extract token
    case .failure(let error):    // handle error
    }
}

// 4. Cleanup — call when done
FinvuAuthenticationNativeWrapper.shared.cleanupAll()
```

---

> **Note:** Silent Network Authentication requires mobile data ON and Wi-Fi OFF.
