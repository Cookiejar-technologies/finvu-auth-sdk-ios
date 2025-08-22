import Foundation
import FinvuAuthenticationSDK

enum Constants {
    static let webViewBaseURL = "https://test-web-app-8a50c.web.app"
    
    enum Config {
        static let appId = ""
        static let requestId = ""
    }
    
    enum Environment {
        case development
        case production
        
        var value:  FinvuAuthenticationSDK.FinvuAuthEnvironment {
            switch self {
            case .development:
                return .development
            case .production:
                return .production
            }
        }
    }
}
