# FinvuAuthenticationSDK

A simple, secure iOS SDK for integrating Finvu authentication into your app, with seamless support for WebView-based flows and JavaScript bridging.

---

## 📋 Requirements

**Minimum iOS version:** 16.0

**Minimum Swift version:** 5.0

**Minimum Xcode version:** 14.0

---

## 📦 Installation

### Using CocoaPods

Add the following to your `Podfile`:

```ruby
# Podfile configuration
platform :ios, '16.0'
    
# Add Finvu SDK dependency
# Check the latest sdk version in the Latest SDK Versions section
pod 'FinvuAuthenticationSDK', :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git', :tag => 'latest_ios_sdk_version'
```

Then run:
```bash
pod install --repo-update
```

> **Note:** Replace `latest_ios_sdk_version` in your Podfile with the actual version number. Latest version is `0.1.0`.

---

## 📋 Code Guidelines

### 1. Avoid Third-Party Imports in Authentication Flow
In the authentication screens and WebView, ensure that only authentication flow-related code is present. Avoid third-party API requests that do not directly relate to the authentication journey.

```swift
// ❌ Avoid
class AuthViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Avoid analytics, tracking, or unrelated API calls
        ThirdPartyAnalytics.track("auth_started") // Don't do this
        setupWebView()
    }
}

// ✅ Recommended  
class AuthViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView() // Only authentication-related setup
    }
}
```

### 2. Do Not Store Sensitive Data in Local Storage
Avoid storing authentication data in UserDefaults, Keychain, or Core Data within the authentication screens.

```swift
// ❌ Avoid
UserDefaults.standard.set(authToken, forKey: "auth_token")
UserDefaults.standard.set(phoneNumber, forKey: "phone")

// ✅ Recommended - Pass data via completion handlers
func handleAuthSuccess(token: String) {
    // Pass token to calling view controller via delegate or completion
    delegate?.authenticationCompleted(with: token)
}
```

### 3. Clean Data and Instances at the End of Authentication Journey
Always clean up all data when the authentication journey ends, including success, failure, or user exit scenarios.

```swift
// ✅ Always implement cleanup
func authenticationCompleted() {
    // Clear any temporary data
    phoneNumber = nil
    otp = nil
    
    // Cleanup SDK resources
    FinvuAuthenticationWrapper.shared.cleanupAll()
    
    // Dismiss or navigate away
    navigationController?.popViewController(animated: true)
}

override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent {
        FinvuAuthenticationWrapper.shared.cleanupAll()
    }
}
```

### 4. Avoid Redundant Authentication Method Calls
Repeatedly calling the same authentication methods can lead to unnecessary network requests and poor performance.

```javascript
// ❌ Avoid multiple rapid calls
function handleButtonClick() {
    window.finvu_authentication_bridge.startAuth(phoneNumber, "callback");
    window.finvu_authentication_bridge.startAuth(phoneNumber, "callback"); // Redundant
}

// ✅ Use state management to prevent redundant calls
let isAuthInProgress = false;

function handleButtonClick() {
    if (isAuthInProgress) return;
    
    isAuthInProgress = true;
    window.finvu_authentication_bridge.startAuth(phoneNumber, "callback");
}

window.handleStartAuthResponse = (response) => {
    isAuthInProgress = false; // Reset state
    // Handle response
};
```

### 5. Cleanup When User Exits Authentication Journey
Ensure proper cleanup when the user exits the authentication journey through any means (success, failure, back button, app backgrounding).

```swift
// ✅ Handle all exit scenarios
class AuthViewController: UIViewController {
    
    // User taps back button
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            cleanup()
        }
    }
    
    // App goes to background
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc func appDidEnterBackground() {
        cleanup()
    }
    
    func cleanup() {
        FinvuAuthenticationWrapper.shared.cleanupAll()
        // Clear any UI state
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
}
```
---

## 🚀 iOS Integration

### Setup the WebView Bridge

The SDK provides a simple method to set up the WebView bridge. No manual JavaScript interface wiring is needed!

#### UIKit Integration

```swift
import UIKit
import WebKit
import FinvuAuthenticationSDK

class ViewController: UIViewController {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup WKWebView
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        // Setup the bridge with environment
        FinvuAuthenticationWrapper.shared.setupWebView(
            webView,
            viewController: self,
            environment: .production // or .development
        )
        
        // Load your web app
        if let url = URL(string: "https://your-web-app-url") {
            webView.load(URLRequest(url: url))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        FinvuAuthenticationWrapper.shared.cleanupAll()
    }
}
```

#### SwiftUI Integration

```swift
import SwiftUI
import WebKit
import FinvuAuthenticationSDK

struct ContentView: View {
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
                        environment: .production
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)
    }
}

final class WebViewStore: ObservableObject {
    @Published var webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        if let url = URL(string: "https://your-web-app-url") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

### Environment Configuration

The SDK supports different environments for development and production:

- **Development Environment** (`.development`): Enables verbose logging and debug features
- **Production Environment** (`.production`): Minimal logging and optimized performance

```swift
// Development environment (with debug logging)
FinvuAuthenticationWrapper.shared.setupWebView(
    webView,
    viewController: self,
    environment: .development
)

// Production environment (minimal logging)
FinvuAuthenticationWrapper.shared.setupWebView(
    webView,
    viewController: self,
    environment: .production
)
```

### Memory Management

**Important:** Always call `cleanupAll()` when the authentication flow is complete to prevent memory leaks and ensure proper resource cleanup.

```swift
// In your view controller
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    FinvuAuthenticationWrapper.shared.cleanupAll()
}

// Or when authentication is complete
func authenticationCompleted() {
    FinvuAuthenticationWrapper.shared.cleanupAll()
}

// In AppDelegate when app terminates
func applicationWillTerminate(_ application: UIApplication) {
    FinvuAuthenticationWrapper.shared.cleanupAll()
}
```

---

## 🌐 WebView/JavaScript Usage

Once the bridge is set up, your web app can call the following methods from JavaScript:

### iOS Bridge Setup

For iOS, the bridge is accessed through WebKit message handlers. Add this polyfill to support the iOS bridge:
**Critical:** Maintain exact parameter naming throughout your iOS polyfill implementation to match SDK expectations. All parameter names must be consistent across bridge methods.

```javascript
// ✅ Consistent parameter naming in iOS polyfill
if (
  typeof window !== "undefined" &&
  !window.finvu_authentication_bridge &&
  window.webkit &&
  window.webkit.messageHandlers &&
  window.webkit.messageHandlers.finvu_authentication_bridge
) {
  window.finvu_authentication_bridge = {
    initAuth: function (initConfig, callback) {
      window.webkit.messageHandlers.finvu_authentication_bridge.postMessage({
        method: "initAuth",// Use exact same name
        initConfig,  // Use exact same name
        callback
      });
    },
    startAuth: function (phoneNumber, callback) {
      window.webkit.messageHandlers.finvu_authentication_bridge.postMessage({
        method: "startAuth",// Use exact same name
        phoneNumber,  // Use exact same name
        callback
      });
    },
    verifyOtp: function (phoneNumber, otp, callback) {
      window.webkit.messageHandlers.finvu_authentication_bridge.postMessage({
        method: "verifyOtp",// Use exact same name
        phoneNumber,  // Use exact same name
        otp,          // Use exact same name
        callback
      });
    }
  };
}

// ❌ Inconsistent naming will cause issues
const config = { appId: "...", requestId: "..." };  // Wrong variable name
const authConfig = { appId: "...", requestId: "..." };  // Wrong variable name

// ✅ Use consistent naming
const initConfig = { appId: "...", requestId: "..." };  // Correct variable name
```

### Available Methods

```javascript
// Initialize the SDK with your app configuration
window.finvu_authentication_bridge.initAuth(initConfig, callbackName);

// Start authentication with phone number
window.finvu_authentication_bridge.startAuth(phoneNumber, callbackName);

// Verify OTP
window.finvu_authentication_bridge.verifyOtp(phoneNumber, otp, callbackName);
```

### Method Details

#### 1. initAuth(initConfig, callbackName)
Initializes the Finvu authentication SDK.

**Parameters:**
- `initConfig` (string): JSON configuration object containing your app ID and request ID
- `callbackName` (string): JavaScript callback function name

**Required fields in initConfig:**
- `appId` (string): Your application ID
- `requestId` (string): Unique request identifier

**Example:**
```javascript
const initConfig = {
  appId: "YOUR_APP_ID",
  requestId: "YOUR_REQUEST_ID"
};
window.finvu_authentication_bridge.initAuth(JSON.stringify(initConfig), "handleInitAuthResponse");
```

**Success Response:**
```json
{
  "status": "SUCCESS",
  "statusCode": "200"
}
```

**Failure Responses:**
```json
// Missing or empty app ID or request ID
{
  "status": "FAILURE",
  "errorCode": "1001",
  "errorMessage": "appId and requestId are required"
}

// SDK initialization failed
{
  "status": "FAILURE",
  "errorCode": "1002",
  "errorMessage": "Authentication failed, SDK initialization failed. Please try initializing the SDK again."
}
```

#### 2. startAuth(phoneNumber, callbackName)
Starts the authentication process for a phone number.

**Parameters:**
- `phoneNumber` (string): User's mobile number (without country code)
- `callbackName` (string): JavaScript callback function name

**Example:**
```javascript
window.finvu_authentication_bridge.startAuth("9876543210", "handleStartAuthResponse");
```

**Success Responses:**
```json
// OTP sent successfully
{
  "status": "INITIATE",
  "statusCode": "200",
  "authType": "SILENT_AUTH",
  "deliveryChannel": ""
}

// Authentication completed with token
{
  "status": "SUCCESS",
  "statusCode": "200",
  "authType": "SILENT_AUTH",
  "token": "your_auth_token_here"
}
```

**Failure Responses:**
```json
// Invalid phone number format
{
  "status": "FAILURE",
  "errorCode": "1001",
  "errorMessage": "Invalid phone number format"
}

// Silent Network Authentication failed
{
  "status": "FAILURE",
  "errorCode": "1002",
  "errorMessage": "Authentication failed, SNA failed."
}

// Generic failure
{
  "status": "FAILURE",
  "errorCode": "1002",
  "errorMessage": "Authentication failed, something went wrong."
}
```

#### 3. verifyOtp(phoneNumber, otp, callbackName)
Verifies the OTP entered by the user.

**Parameters:**
- `phoneNumber` (string): User's mobile number (same as used in startAuth)
- `otp` (string): OTP entered by user
- `callbackName` (string): JavaScript callback function name

**Example:**
```javascript
window.finvu_authentication_bridge.verifyOtp("9876543210", "123456", "handleVerifyOtpResponse");
```

**Success Response:**
```json
{
  "status": "SUCCESS",
  "statusCode": "200",
  "authType": "OTP",
  "token": "your_auth_token_here"
}
```

**Failure Responses:**
```json
// Invalid OTP format
{
  "status": "FAILURE",
  "errorCode": "1001",
  "errorMessage": "Invalid OTP format"
}

// OTP verification failed
{
  "status": "FAILURE",
  "errorCode": "1002",
  "errorMessage": "Authentication failed, something went wrong."
}
```

### Callback Flow & Status Handling

> **Important:** After calling `startAuth(phoneNumber, callbackName)`, the same callback function will be invoked for all subsequent statuses in the authentication flow, including `INITIATE`, `OTP_AUTO_READ`, `VERIFY`, and `SUCCESS`.
>
> - **Silent Authentication**: If `authType` is `SILENT_AUTH`, wait for a `SUCCESS` status with a `token` in the same callback before proceeding.
> - **OTP Flow**: If `authType` is `OTP`, prompt the user to enter the OTP, then call `verifyOtp`. The response will be delivered to its own callback.
> - **Auto-read**: If OTP auto-read is successful, you may receive `OTP_AUTO_READ` and then `SUCCESS` automatically.

### Example Integration

```javascript
// Set up global callback functions
window.handleInitAuthResponse = (response) => {
  try {
    const data = JSON.parse(response);
    if (data.error) {
      console.log(`Init Auth Error: ${data.error}`);
    } else {
      console.log(`Init Auth: ${response}`);
      // Proceed with authentication
    }
  } catch {
    console.log(`Init Auth: ${response}`);
  }
};

window.handleStartAuthResponse = (response) => {
  try {
    const data = JSON.parse(response);
    if (data.error) {
      console.log(`Start Auth Error: ${data.error}`);
    } else {
      console.log(`Start Auth: ${response}`);
      // Handle different status types
      switch (data.status) {
        case "INITIATE":
          // Show OTP input field
          showOtpInput();
          break;
        case "SUCCESS":
          if (data.token) {
            handleAuthSuccess(data.token);
          }
          break;
        case "FAILURE":
          showError(data.errorMessage);
          break;
      }
    }
  } catch {
    console.log(`Start Auth: ${response}`);
  }
};

window.handleVerifyOtpResponse = (response) => {
  try {
    const data = JSON.parse(response);
    if (data.error) {
      console.log(`Verify OTP Error: ${data.error}`);
    } else {
      console.log(`Verify OTP: ${response}`);
      if (data.status === "SUCCESS" && data.token) {
        handleAuthSuccess(data.token);
      }
    }
  } catch {
    console.log(`Verify OTP: ${response}`);
  }
};

// Usage functions
function callInitAuth() {
  try {
    const initConfig = {
      appId: "YOUR_APP_ID",
      requestId: "YOUR_REQUEST_ID"
    };
    window.finvu_authentication_bridge.initAuth(JSON.stringify(initConfig), "handleInitAuthResponse");
  } catch (error) {
    alert("initAuth failed: " + error);
  }
}

function callStartAuth(phoneNumber) {
  if (!phoneNumber || phoneNumber.length < 10) {
    alert("Please enter a valid phone number");
    return;
  }
  try {
    window.finvu_authentication_bridge.startAuth(phoneNumber, "handleStartAuthResponse");
  } catch (error) {
    alert("startAuth failed: " + error);
  }
}

function callVerifyOtp(phoneNumber, otp) {
  if (!phoneNumber || phoneNumber.length < 10) {
    alert("Please enter a valid phone number");
    return;
  }
  if (!otp || otp.length !== 6) {
    alert("Please enter a valid 6-digit OTP");
    return;
  }
  try {
    window.finvu_authentication_bridge.verifyOtp(phoneNumber, otp, "handleVerifyOtpResponse");
  } catch (error) {
    alert("verifyOtp failed: " + error);
  }
}
```

---

## 📤 Response Format & Error Code Reference

### Response Structure

**Success Responses** contain:
- `status`: Operation status (SUCCESS, INITIATE, etc.)
- `statusCode`: HTTP-style status code (e.g., "200")
- Additional fields like `token`, `authType`, `otp`, etc.

**Failure Responses** contain:
- `status`: Always "FAILURE"
- `errorCode`: Specific error code for troubleshooting
- `errorMessage`: Human-readable error description

### Status Types

| Status              | Description                          | Next Action                        |
|---------------------|--------------------------------------|------------------------------------|
| SUCCESS             | Operation completed successfully     | Use token or proceed               |
| FAILURE             | Operation failed                     | Handle error, retry if appropriate |
| INITIATE            | OTP sent, waiting for user input     | Show OTP input field               |
| OTP_AUTO_READ       | OTP automatically read from SMS      | Auto-submit or show OTP            |
| VERIFY              | Authentication verified              | Wait for SUCCESS with token       |
| DELIVERY_STATUS     | SMS delivery status update           | Show delivery information          |
| FALLBACK_TRIGGERED  | Fallback authentication triggered    | Handle fallback flow               |

### Error Codes (Only in Failure Responses)

| Error Code | Description                    | Common Causes                                    |
|------------|--------------------------------|--------------------------------------------------|
| 1001       | Invalid parameter              | Missing appId/requestId, invalid phone number/OTP format  |
| 1002       | Generic failure                | Network issues, service unavailable             |
| 5003       | SDK initialization failed      | Invalid app ID, network connectivity issues     |
| 9106       | Silent Network Auth failed     | SIM/network conditions not met                  |

### Input Validation Rules

- **Phone Number**: 10 digits, cannot start with 0
- **OTP**: 4-8 digits only
- **App ID**: Required, cannot be empty
- **Request ID**: Required, cannot be empty

---

## ❓ FAQ

### Q: What conditions are required for Silent Network Authentication (SNA)?
**A:** For SNA to work properly:
- **SIM internet must be ON** (mobile data enabled)
- **WiFi must be OFF** (disconnect from WiFi networks)
- Device must have active mobile network connectivity
- SIM card must support the required network protocols

If these conditions are not met, the SDK will automatically fall back to OTP-based authentication.

### Q: Why am I getting error code 1001?
**A:** Error 1001 indicates invalid parameters. Check:
- App ID and Request ID are provided and not empty in initAuth
- Phone number format is correct (7-15 digits, no leading zero)
- OTP format is correct (4-8 digits) when calling verifyOtp

### Q: How do I handle multiple authentication statuses?
**A:** Use the same callback function for startAuth to receive all status updates (INITIATE, OTP_AUTO_READ, VERIFY, SUCCESS). Each status provides context for the next step in the authentication flow.

### Q: Can I use this SDK with UIWebView?
**A:** No, the SDK requires WKWebView. UIWebView is deprecated and doesn't support the modern JavaScript bridging features needed.

### Q: How do I handle memory management?
**A:** Always call `cleanupAll()` when done with authentication. The SDK uses weak references to prevent retain cycles.

---