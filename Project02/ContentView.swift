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

class MFAViewModel: ObservableObject {
    @Published var qrImage: UIImage?
    @Published var verificationResult: String = ""

    // Decode Base64 → UIImage
    func decodeBase64QR(_ base64: String) -> UIImage? {
        let cleaned = base64
            .replacingOccurrences(of: "\\n", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = Data(base64Encoded: cleaned) else {
            print(" Base64 decode failed")
            return nil
        }

        return UIImage(data: data)
    }

    // Fetch QR code
    func fetchQR(email: String) {
        let urlString =
            "https://wa-ocu-mfa-fre6d6guhve2afcw.centralus-01.azurewebsites.net/mfa/setup/qr/\(email)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            // Try direct Base64
            if let base64 = String(data: data, encoding: .utf8),
               let image = self.decodeBase64QR(base64) {

                DispatchQueue.main.async { self.qrImage = image }
                return
            }

            // JSON response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let base64 = json["qr"] as? String,
               let image = self.decodeBase64QR(base64) {

                DispatchQueue.main.async { self.qrImage = image }
                return
            }

            print("❌ Could not decode QR response.")
        }
        .resume()
    }

    // helps verify code
    func verifyCode(id: String, code: String, completion: @escaping (Bool) -> Void) {

        let url = URL(string:
            "https://wa-ocu-mfa-fre6d6guhve2afcw.centralus-01.azurewebsites.net/mfa/verify/auth"
        )!

        let body: [String: String] = [
            "id": id,
            "code": code
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = String(data: data, encoding: .utf8) else {
                completion(false)
                return
            }

            DispatchQueue.main.async {
                completion(result.lowercased().contains("true"))
            }
        }
        .resume()
    }
}

// contentview main page
struct ContentView: View {

    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var mfaMethod: MFAMethod = .choice

    @State private var showForgotPassword = false
    @State private var showMFASheet = false

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
//button for frogot password
                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .padding(.top, 8)
            }
            .padding()
            .sheet(isPresented: $showMFASheet) {
                MFAVerificationView(
                    email: email,
                    mfaMethod: $mfaMethod,
                    onVerified: handleMFAVerified
                )
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
//our function when login is tapped
    func login() {
        print("Login tapped")
        mfaMethod = .choice
        showMFASheet = true
    }
// haldes mfa and prints mfa completed successfully
    func handleMFAVerified() {
        print("MFA Completed Successfully")
        isLoggedIn = true
        showMFASheet = false
    }
}

// shows mfa verification screen
struct MFAVerificationView: View {

    let email: String
    @Binding var mfaMethod: MFAMethod
    var onVerified: () -> Void

    var body: some View {
        VStack(spacing: 25) {

            Text("Multi-Factor Authentication")
                .font(.title2)
                .bold()

            switch mfaMethod {
            case .choice:
                Button("Verify by Email (QR Code)") { mfaMethod = .email }
                Button("Verify by SMS") { mfaMethod = .sms }
                Button("Use Authenticator App") { mfaMethod = .authenticator }
                Button("Answer Security Questions") { mfaMethod = .securityQuestions }

            case .email:
                EmailQRView(email: email, onSuccess: onVerified)

            case .sms:
                SMSVerificationView(onSuccess: onVerified)

            case .authenticator:
                AuthenticatorView(email: email, onSuccess: onVerified)

            case .securityQuestions:
                SecurityQuestionsView(onSuccess: onVerified)
            }

            Button("Back") { mfaMethod = .choice }
                .padding(.top)
        }
        .padding()
    }
}

// Email and QR code
struct EmailQRView: View {

    let email: String
    var onSuccess: () -> Void
    @StateObject var vm = MFAViewModel()
    @State private var code = ""

    var body: some View {
        VStack(spacing: 20) {

            Text("Scan the QR code in your Authenticator App")

            if let img = vm.qrImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            } else {
                ProgressView("Loading QR...")
                    .onAppear {
                        vm.fetchQR(email: email)
                    }
            }

            TextField("Enter 6-digit code", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Button("Verify Code") {
                vm.verifyCode(id: email, code: code) { success in
                    if success { onSuccess() }
                }
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// sms mfa
struct SMSVerificationView: View {
    var onSuccess: () -> Void
    @State private var code = ""

    var body: some View {
        VStack {
            Text("Enter SMS Code").bold()
            TextField("6-digit code", text: $code)
                .textFieldStyle(.roundedBorder)

            Button("Verify") {
                print("SMS Verified")
                onSuccess()
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// authenticator app
struct AuthenticatorView: View {

    let email: String
    var onSuccess: () -> Void

    @StateObject var vm = MFAViewModel()
    @State private var otp = ""

    var body: some View {
        VStack {
            Text("Enter Authenticator Code").bold()

            TextField("6-digit code", text: $otp)
                .textFieldStyle(.roundedBorder)

            Button("Verify") {
                vm.verifyCode(id: email, code: otp) { success in
                    if success { onSuccess() }
                }
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
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

            TextField("Favorite color?", text: $answer1)
                .textFieldStyle(.roundedBorder)

            TextField("City born in?", text: $answer2)
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

// foropgt passwords
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

//preview purposes
#Preview {
    ContentView()
}
