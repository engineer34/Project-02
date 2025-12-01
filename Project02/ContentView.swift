//
//  ContentView.swift
//  Project02

import CoreImage.CIFilterBuiltins
import SwiftUI
import FirebaseAuth

//mfa options
enum MFAMethod {
    case choice
    case email
    case sms
    case authenticator
    case securityQuestions
}

struct ContentView: View {
// sets isLogged in to false so you
    @AppStorage("isLoggedIn") var isLoggedIn = false

    @State private var email = ""
    @State private var password = ""
    @State private var showingSignup = false
    @State private var showingMFA = false
    @State private var mfaMethod: MFAMethod = .choice
   
    @State private var showForgotPassword = false
    @State private var showMFASheet = false
    
//connects to loginview
    var body: some View {
        NavigationView {
                    VStack(spacing: 20) {
                        Text("Project02 — Login")
                            .font(.largeTitle)
                            .bold()

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                      
                        Button(action: login) {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
//cretae button forgot password
                        Button("Forgot Password?") {
                                           showForgotPassword = true
                                       }
                                       .padding(.top, 8)

                                   }
                                   .padding()
                                   .sheet(isPresented: $showMFASheet) {
                                       MFAVerificationView(
                                           mfaMethod: $mfaMethod,
                                           onVerified: handleMFAVerified
                                       )
                                   }
                                   .sheet(isPresented: $showForgotPassword) {
                                       ForgotPasswordView()
                                   }
                               }
                           }

                           // function for login logic
                           func login() {
                               //prints login tapped
                               print("Login tapped")
                               
                               mfaMethod = .choice    // helps reset MFA options
                               showMFASheet = true    // starts MFA flow
                           }

                           // function handles MFA if isLogged in equals true it prints completed successfully
                           func handleMFAVerified() {
                               print("MFA Completed Successfully")
                               isLoggedIn = true
                               showMFASheet = false
                           }
                       }

                       // MFA selections and Steps
                       struct MFAVerificationView: View {

                           @Binding var mfaMethod: MFAMethod
                           var onVerified: () -> Void

                           var body: some View {
                               VStack(spacing: 25) {

                                   Text("Multi-Factor Authentication")
                                       .font(.title2)
                                       .bold()

                                   switch mfaMethod {
//verify by email
                                   case .choice:
                                       Button("Verify by Email Code") { mfaMethod = .email }
                                       //verify sms code
                                       Button("Verify by SMS Code") { mfaMethod = .sms }
                                       //use authenticator button
                                       Button("Use Authenticator App") { mfaMethod = .authenticator }
                                     //  security questions
                                       Button("Answer Security Questions") { mfaMethod = .securityQuestions }

                                   case .email:
                                       EmailVerificationView(onSuccess: onVerified)

                                   case .sms:
                                       SMSVerificationView(onSuccess: onVerified)

                                   case .authenticator:
                                       AuthenticatorView(onSuccess: onVerified)

                                   case .securityQuestions:
                                       SecurityQuestionsView(onSuccess: onVerified)
                                   }

                                   Button("Back") { mfaMethod = .choice }
                                       .padding(.top)
                               }
                               .padding()
                           }
                       }

                       // email verification mfa
                       struct EmailVerificationView: View {
                           var onSuccess: () -> Void
                           @State private var code = ""

                           var body: some View {
                               VStack {
                                   Text("Enter Email Code").bold()
                                   TextField("6-digit code", text: $code)
                                       .textFieldStyle(.roundedBorder)

                                   Button("Verify") {
                                       print("Email Code Verified")
                                       onSuccess()
                                   }
                                   .padding()
                                   .background(.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                               }
                           }
                       }

                       // SMS-MFA
                       struct SMSVerificationView: View {
                           var onSuccess: () -> Void
                           @State private var code = ""

                           var body: some View {
                               VStack {
                                   Text("Enter SMS Code").bold()
                                   TextField("6-digit code", text: $code)
                                       .textFieldStyle(.roundedBorder)

                                   Button("Verify") {
                                       print("SMS Code Verified")
                                       onSuccess()
                                   }
                                   .padding()
                                   .background(.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                               }
                           }
                       }

                       // Authenticator
                       struct AuthenticatorView: View {
                           var onSuccess: () -> Void
                           @State private var otp = ""

                           var body: some View {
                               VStack {
                                   Text("Enter Authenticator Code").bold()
                                   TextField("6-digit code", text: $otp)
                                       .textFieldStyle(.roundedBorder)

                                   Button("Verify") { onSuccess() }
                                       .padding()
                                       .background(.blue)
                                       .foregroundColor(.white)
                                       .cornerRadius(10)
                               }
                           }
                       }

                       // security questions
                       struct SecurityQuestionsView: View {
                           var onSuccess: () -> Void
                           @State private var answer1 = ""
                           @State private var answer2 = ""

                           var body: some View {
                               VStack {
                                   Text("Security Questions").bold()

                                   TextField("What is your favorite color?", text: $answer1)
                                       .textFieldStyle(.roundedBorder)

                                   TextField("What city were you born in?", text: $answer2)
                                       .textFieldStyle(.roundedBorder)

                                   Button("Verify") {
                                       print("Security questions verified")
                                       onSuccess()
                                   }
                                   .padding()
                                   .background(.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                               }
                               .padding()
                           }
                       }

                       // forogt password view
                       struct ForgotPasswordView: View {

                           @Environment(\.dismiss) var dismiss
                           @State private var email = ""

                           var body: some View {
                               VStack {
                                   Text("Forgot Password")
                                       .font(.title2)
                                       .bold()

                                   TextField("Enter your email", text: $email)
                                       .textFieldStyle(.roundedBorder)
                                       .padding()
//button tjat sends reset link doesn't work
                                   Button("Send Reset Link") {
                                       print("Pretending to send password reset email…")
                                       dismiss()
                                   }
                                   .padding()
                                   .background(.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(12)
                               }
                               .padding()
                           }
                       }
//for preview purposes
                       #Preview {
                           ContentView()
                       }
