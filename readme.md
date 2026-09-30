# Finvu Auth SDK — iOS

**Version:** `1.1.1` · **iOS:** 15.0+ · **Swift:** 5.0+ · **Xcode:** 14+

Silent Network Authentication (SNA) and Device Binding SDK for iOS, with WKWebView bridge support for web-based authentication flows.

---

## Installation

Add to your `Podfile`:

```ruby
platform :ios, '15.0'

pod 'FinvuAuthenticationSDK', :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git', :tag => 'v1.1.1'
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


### Info.plist — Face ID

Required if you use Device Binding (native or WebView). Without it, iOS never offers Face ID and the prompt falls back to the passcode.

```xml
<key>NSFaceIDUsageDescription</key>
<string>Face ID is used to confirm it's you before binding or verifying this device.</string>
```

> If your project generates its Info.plist (`GENERATE_INFOPLIST_FILE = YES`), set the build setting `INFOPLIST_KEY_NSFaceIDUsageDescription` instead.

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

Use this if your app handles the authentication flow entirely in Swift, without a WebView. The SDK offers two factors: **SNA** (Silent Network Authentication) and **Device Binding** (a Secure Enclave key that proves "this user, on this device").

Every method completes with `Result<[String: Any], FinvuAuthException>`. `FinvuAuthException` has `status`, `errorCode` and `errorMessage`.

```swift
import FinvuAuthenticationSDK

let finvu = FinvuAuthenticationNativeWrapper.shared

// Setup — call once, before any other method
finvu.setup(viewController: self, environment: .production)  // or .development

// Cleanup — call when done or the user exits
finvu.cleanupAll()
```

#### SNA

```swift
// 1. Init — call with the requestId from your backend
finvu.initSNA(config: ["requestId": "REQUEST_ID"]) { result in
    switch result {
    case .success(let response):
        // ["status": "SUCCESS", "mcc": "404", "mnc": "90", ...] — proceed to startSNA
        break
    case .failure(let error):
        print(error.errorCode ?? "", error.errorMessage)
    }
}

// 2. Start SNA — call with the SNA URL returned by your backend
finvu.startSNA(snaUrl: "SNA_URL") { result in
    switch result {
    case .success(let response):
        let snaToken = response["snaToken"] as? String  // send to your backend
    case .failure(let error):
        print(error.errorCode ?? "", error.errorMessage)
    }
}
```

`initAuth(config:)` / `startAuth(snaUrl:)` are also supported and behave exactly like `initSNA` / `startSNA`.

The `requestId` passed to `initSNA` is attached to every SNA event the SDK logs.

#### Device Binding

Device binding creates a key pair in the Secure Enclave. The private key never leaves the device and can only be used after the user unlocks with Face ID / Touch ID or the device passcode. Your backend stores the public key and verifies signatures with it.

> Requires `NSFaceIDUsageDescription` in `Info.plist` — see [Info.plist — Face ID](#infoplist--face-id). Not available on the Simulator (reports `UNSUPPORTED`).

**Typical flow**

1. **Check** — `getDeviceBindingState` with the `keyId` you stored for this user.
2. **Enroll** (state `NOT_ENROLLED` / `INVALIDATED`, or a new device) — `enrollDeviceBinding`, then store the returned `keyId` + `publicKey` on your backend against the user.
3. **Verify** — your backend issues a challenge; call `signDeviceBindingChallenge` with every `keyId` it has for the user; your backend verifies the returned signature.

```swift
// 1. Check state — local, no prompt, no network. Omit keyId to only check device support.
finvu.getDeviceBindingState(config: ["keyId": "STORED_KEY_ID"]) { result in
    if case .success(let response) = result {
        let state = response["state"] as? String  // ENROLLED, NOT_ENROLLED, INVALIDATED, UNSUPPORTED, NO_SCREEN_LOCK
    }
}

// 2. Enroll — shows the device-lock prompt, then creates a new key
finvu.enrollDeviceBinding(config: [
    "requestId": "REQUEST_ID",
    "promptTitle": "Verify it's you",                     // optional
    "promptSubtitle": "Confirm to secure your account",   // optional
]) { result in
    switch result {
    case .success(let response):
        let keyId = response["keyId"] as? String          // store on your backend
        let publicKey = response["publicKey"] as? String  // store on your backend
    case .failure(let error):
        print(error.errorCode ?? "", error.errorMessage)  // see error codes below
    }
}

// 3. Sign — shows the device-lock prompt, then signs the challenge
finvu.signDeviceBindingChallenge(config: [
    "requestId": "REQUEST_ID",
    "allowedKeyIds": ["KEY_ID_1", "KEY_ID_2"],  // every keyId your backend has for this user
    "challenge": "SERVER_CHALLENGE",
]) { result in
    switch result {
    case .success(let response):
        let signature = response["signature"] as? String  // send with keyId to your backend
    case .failure(let error):
        print(error.errorCode ?? "", error.errorMessage)  // see error codes below
    }
}
```

**Parameters**

| Method | Key | Required | Description |
|---|---|---|---|
| `getDeviceBindingState` | `keyId` | No | `keyId` from a previous enroll. Omit to only check whether the device supports device binding. |
| `enrollDeviceBinding` | `requestId` | Recommended | Your backend's request id; attached to the logged events. |
| | `promptTitle`, `promptSubtitle` | No | Reason text shown on the Face ID / passcode prompt. |
| | `attestationChallenge` | No | Accepted for parity with Android; iOS has no key attestation, so it is unused. |
| `signDeviceBindingChallenge` | `allowedKeyIds` | Yes | Array of every `keyId` your backend has for this user (a single string is also accepted). The SDK signs with whichever exists on this device. |
| | `challenge` | Yes | Server-issued challenge. Signed exactly as its UTF-8 bytes. |
| | `requestId` | Recommended | Your backend's request id; attached to the logged events. |
| | `promptTitle`, `promptSubtitle` | No | Reason text shown on the Face ID / passcode prompt. |

`entityId` may also be passed to `enrollDeviceBinding` / `signDeviceBindingChallenge` and is attached to the logged events.

**Success responses**

```json
// getDeviceBindingState — keyId only when state is ENROLLED or INVALIDATED
{"status":"SUCCESS","state":"ENROLLED","keyId":"6F1C2A9E-3B7D-4C1A-9E2F-8A5B3C7D1E90"}

// enrollDeviceBinding
{"status":"SUCCESS","keyId":"6F1C2A9E-...","publicKey":"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...","algorithm":"ES256"}

// signDeviceBindingChallenge
{"status":"SUCCESS","keyId":"6F1C2A9E-...","signature":"MEUCIQD...","algorithm":"ES256"}
```

| State | Meaning | What to do |
|---|---|---|
| `ENROLLED` | Key exists and is usable | Sign |
| `NOT_ENROLLED` | No key for this `keyId` on this device (or no `keyId` passed) | Enroll |
| `INVALIDATED` | Face ID / Touch ID enrollment changed; the key has been removed | Enroll again and replace the `keyId` on your backend |
| `UNSUPPORTED` | Device cannot do device binding (e.g. Simulator) | Use another factor |
| `NO_SCREEN_LOCK` | No passcode set | Ask the user to set a passcode |

**Error codes** (`FinvuAuthException.errorCode`)

| errorCode | Method | When | Suggested handling |
|---|---|---|---|
| `DEVICE_NOT_SECURE` | enroll | No passcode on the device | Ask the user to set a passcode |
| `DEVICE_BINDING_UNSUPPORTED` | enroll, sign | No Secure Enclave, or Face ID / passcode unavailable | Use another factor |
| `DEVICE_BINDING_NOT_ENROLLED` | sign | None of `allowedKeyIds` exist on this device, or the list is empty | Treat as a new device: verify the user another way, then enroll |
| `DEVICE_BINDING_KEY_INVALIDATED` | sign | Face ID / Touch ID changed; the key has been removed | Enroll again and replace the `keyId` |
| `DEVICE_BINDING_USER_CANCELLED` | enroll, sign | User dismissed the prompt | Let the user retry |
| `DEVICE_BINDING_AUTH_FAILED` | enroll, sign | Prompt failed (e.g. too many attempts) | Show the message; retry later |
| `DEVICE_BINDING_ENROLL_FAILED` | enroll | Key could not be created | Retry, then fall back |
| `DEVICE_BINDING_SIGN_FAILED` | sign | Signing failed | Retry, then fall back |
| `INVALID_CHALLENGE` | sign | `challenge` missing or empty | Fix the request |

**Backend verification**

- Store `keyId` and `publicKey` per user **per device**; a user may have several.
- `publicKey` is a Base64 X.509 SubjectPublicKeyInfo (EC P-256). Verify `signature` (Base64, DER-encoded ECDSA) as **ES256 / SHA256withECDSA** over the UTF-8 bytes of the challenge you issued.
- After re-enrolling on the same device, replace that device's old `keyId`; on a new device, add the new one.
- On iOS, keys stay in the Keychain after the app is uninstalled, so a reinstalled app can still sign with its old `keyId`. Require a fresh enroll on your backend if a reinstall should unbind the device.

#### Capabilities

```swift
let capabilities = finvu.getCapabilities()
// ["status": "SUCCESS", "sdkVersion": "1.1.1", "platform": "ios", "bridgeVersion": 2, "factors": ["SNA", "DEVICE_BINDING"], "supportedMethods": [...]]
```

---

## Demo App

See [`finvuauthsdkdemoswiftui/`](./finvuauthsdkdemoswiftui) for a complete working example.


---

## Support

support@cookiejar.co.in · [finvu.in](https://finvu.in)
