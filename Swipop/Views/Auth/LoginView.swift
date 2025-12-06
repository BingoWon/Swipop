//
//  LoginView.swift
//  Swipop
//
//  Modern authentication view with social login and email sign-in
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var showResetPassword = false
    @State private var resetEmailSent = false
    @State private var confirmationEmail: String?

    @FocusState private var focusedField: Field?

    private let auth = AuthService.shared

    private enum AuthMode {
        case signIn, signUp
        var title: String { self == .signIn ? "Sign In" : "Sign Up" }
        var buttonTitle: String { self == .signIn ? "Sign In" : "Create Account" }
        var switchPrompt: String { self == .signIn ? "Don't have an account?" : "Already have an account?" }
        var switchAction: String { self == .signIn ? "Sign Up" : "Sign In" }
    }

    private enum Field: Hashable { case email, password, confirmPassword }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let email = confirmationEmail {
                emailConfirmationView(email: email)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        socialButtons
                        divider
                        emailForm
                        switchModeButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if auth.isLoading { loadingOverlay }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordSheet(email: email, emailSent: $resetEmailSent)
                .presentationDetents([.height(320)])
                .glassSheetBackground()
        }
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth { isPresented = false }
        }
    }

    // MARK: - Email Confirmation View

    private func emailConfirmationView(email: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("Check your inbox")
                    .font(.system(size: 24, weight: .bold))

                Text("We sent a confirmation link to")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text(email)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.brand)
            }

            Text("Click the link in the email to activate your account, then return here to sign in.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    confirmationEmail = nil
                    mode = .signIn
                } label: {
                    Text("Back to Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
                }

                Button { isPresented = false } label: {
                    Text("Close")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Swipop")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .brand], startPoint: .leading, endPoint: .trailing)
                    )

                Text(mode.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: 12) {
            // Apple
            SocialLoginButton(
                icon: Image(systemName: "apple.logo"),
                title: "Continue with Apple",
                style: colorScheme == .dark ? .light : .dark
            ) {}
                .overlay {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .blendMode(.destinationOver)
                    .opacity(0.02)
                }

            // Google
            SocialLoginButton(
                icon: Image("GoogleLogo"),
                title: "Continue with Google",
                style: .outline
            ) {
                Task { await handleGoogle() }
            }

            // GitHub
            SocialLoginButton(
                icon: Image("GitHubLogo").renderingMode(.template),
                title: "Continue with GitHub",
                style: .outline
            ) {
                Task { await handleGitHub() }
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
            Text("or").font(.system(size: 13)).foregroundStyle(.tertiary)
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
        }
    }

    // MARK: - Email Form

    private var emailForm: some View {
        VStack(spacing: 14) {
            // Email
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focusedField == .email ? Color.brand : Color.clear, lineWidth: 1.5)
                )

            // Password
            HStack(spacing: 0) {
                Group {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .textContentType(mode == .signUp ? .newPassword : .password)
                .focused($focusedField, equals: .password)

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(focusedField == .password ? Color.brand : Color.clear, lineWidth: 1.5)
            )

            // Confirm Password (sign up)
            if mode == .signUp {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focusedField == .confirmPassword ? Color.brand : Color.clear, lineWidth: 1.5)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Forgot password
            if mode == .signIn {
                HStack {
                    Spacer()
                    Button { showResetPassword = true } label: {
                        Text("Forgot password?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.brand)
                    }
                }
            }

            // Submit
            Button(action: submitForm) {
                Text(mode.buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.5)
        }
        .animation(.easeInOut(duration: 0.2), value: mode)
    }

    // MARK: - Switch Mode

    private var switchModeButton: some View {
        HStack(spacing: 4) {
            Text(mode.switchPrompt).foregroundStyle(.secondary)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = mode == .signIn ? .signUp : .signIn
                    errorMessage = nil
                    confirmPassword = ""
                }
            } label: {
                Text(mode.switchAction).fontWeight(.semibold).foregroundStyle(Color.brand)
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Loading

    private var loadingOverlay: some View {
        Color.appBackground.opacity(0.8).ignoresSafeArea()
            .overlay { ProgressView().tint(.brand).scaleEffect(1.2) }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passOK = password.count >= 8
        return mode == .signUp ? emailOK && passOK && password == confirmPassword : emailOK && passOK
    }

    // MARK: - Actions

    private func submitForm() {
        focusedField = nil
        errorMessage = nil
        Task {
            do {
                if mode == .signUp {
                    let result = try await auth.signUp(email: email, password: password)
                    if case let .confirmationRequired(email) = result {
                        confirmationEmail = email
                    }
                } else {
                    try await auth.signIn(email: email, password: password)
                }
            } catch { errorMessage = mapError(error) }
        }
    }

    private func handleGitHub() async {
        errorMessage = nil
        do { try await auth.signInWithGitHub() }
        catch { errorMessage = mapError(error) }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case let .success(auth):
            if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                do { try await self.auth.signInWithApple(credential: cred) }
                catch { errorMessage = mapError(error) }
            }
        case let .failure(error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = mapError(error)
            }
        }
    }

    private func handleGoogle() async {
        errorMessage = nil
        do { try await auth.signInWithGoogle() }
        catch {
            if (error as NSError).code != -5 { errorMessage = mapError(error) }
        }
    }

    private func mapError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") || msg.contains("invalid credentials") { return "Invalid email or password" }
        if msg.contains("email not confirmed") { return "Please check your email to confirm your account" }
        if msg.contains("user already registered") { return "An account with this email already exists" }
        if msg.contains("weak password") || msg.contains("password") { return "Password must be at least 8 characters" }
        if msg.contains("rate limit") { return "Too many attempts. Please try again later" }
        if msg.contains("network") { return "Network error. Please check your connection" }
        return "Something went wrong. Please try again"
    }
}

// MARK: - Social Login Button

private struct SocialLoginButton: View {
    let icon: Image
    let title: String
    let style: Style
    let action: () -> Void

    enum Style { case dark, light, outline }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if style == .outline {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                }
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .dark: return .white
        case .light: return .black
        case .outline: return .primary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .dark: return .black
        case .light: return .white
        case .outline: return Color.secondaryBackground
        }
    }
}

// MARK: - Reset Password Sheet

private struct ResetPasswordSheet: View {
    let email: String
    @Binding var emailSent: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var resetEmail: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(email: String, emailSent: Binding<Bool>) {
        self.email = email
        _emailSent = emailSent
        _resetEmail = State(initialValue: email)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if emailSent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Check your email")
                            .font(.system(size: 20, weight: .semibold))
                        Text("We sent a password reset link to\n\(resetEmail)")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                } else {
                    TextField("Email", text: $resetEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))

                    if let error = errorMessage {
                        Text(error).font(.system(size: 13)).foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            isLoading = true
                            errorMessage = nil
                            do {
                                try await AuthService.shared.resetPassword(email: resetEmail)
                                emailSent = true
                            } catch { errorMessage = "Failed to send reset email" }
                            isLoading = false
                        }
                    } label: {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Send Reset Link") }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(isLoading || !resetEmail.contains("@"))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .navigationTitle(emailSent ? "" : "Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

#Preview {
    LoginView(isPresented: .constant(true))
}
