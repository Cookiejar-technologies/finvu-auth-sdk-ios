Pod::Spec.new do |s|
  s.name             = 'FinvuAuthenticationSDK'
  s.version          = '0.1.0'
  s.summary          = 'Authentication wrapper by finvu to support otpless login from webview rendered in parent app.'

  s.description      = 'Authentication wrapper by finvu to support otpless login from webview rendered in parent app.'

  s.homepage         = 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios'
  
  s.author           = { 'Finvu team' => 'pranadw@cookiejar.co.in' }
  s.source           = { :git => 'https://github.com/Cookiejar-technologies/finvu-auth-sdk-ios.git', tag: 'v1.0.0' }

  s.ios.deployment_target = '16.0'

  s.vendored_frameworks = 'FinvuAuthenticationSDK.xcframework','OtplessBM.xcframework'
  s.swift_version    = '5.0'
end
