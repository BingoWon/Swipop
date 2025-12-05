//
//  LoginView.swift
//  Swipop
//
//  Modern authentication view with social login and email sign-in
//

import SwiftUI
import AuthenticationServices

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
    
    @FocusState private var focusedField: Field?
    
    private let auth = AuthService.shared
    
    private enum AuthMode {
        case signIn, signUp
        
        var title: String {
            switch self {
            case .signIn: return "Welcome back"
            case .signUp: return "Create account"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .signIn: return "Sign In"
            case .signUp: return "Create Account"
            }
        }
        
        var switchPrompt: String {
            switch self {
            case .signIn: return "Don't have an account?"
            case .signUp: return "Already have an account?"
            }
        }
        
        var switchAction: String {
            switch self {
            case .signIn: return "Sign Up"
            case .signUp: return "Sign In"
            }
        }
    }
    
    private enum Field: Hashable {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 0) {
                    header
                    
                    VStack(spacing: 24) {
                        socialButtons
                        emailDivider
                        emailForm
                        switchModeButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            if auth.isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordSheet(email: email, emailSent: $resetEmailSent)
                .presentationDetents([.height(320)])
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated { isPresented = false }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Circle()
                .fill(Color.brand.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 150, y: 100)
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
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            VStack(spacing: 12) {
                Text("Swipop")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .brand],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(mode.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Social Buttons (Compact Row)
    
    private var socialButtons: some View {
        HStack(spacing: 12) {
            // Apple
            CompactSocialButton(provider: .apple, colorScheme: colorScheme) {
                // Apple Sign In handled via SignInWithAppleButton
            }
            .overlay {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await handleApple(result) }
                }
                .blendMode(.destinationOver)
                .opacity(0.02)
            }
            
            // Google
            CompactSocialButton(provider: .google, colorScheme: colorScheme) {
                Task { await handleGoogle() }
            }
            
            // GitHub
            CompactSocialButton(provider: .github, colorScheme: colorScheme) {
                Task { await handleGitHub() }
            }
        }
    }
    
    // MARK: - Email Divider
    
    private var emailDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
            
            Text("or with email")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    // MARK: - Email Form
    
    private var emailForm: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focusedField == .email ? Color.brand : Color.clear, lineWidth: 1.5)
                    )
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 0) {
                    Group {
                        if showPassword {
                            TextField("••••••••", text: $password)
                        } else {
                            SecureField("••••••••", text: $password)
                        }
                    }
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focusedField == .password ? Color.brand : Color.clear, lineWidth: 1.5)
                )
            }
            
            // Confirm password (sign up only)
            if mode == .signUp {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    SecureField("••••••••", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(focusedField == .confirmPassword ? Color.brand : Color.clear, lineWidth: 1.5)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
            
            // Forgot password (sign in only)
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
            
            // Submit button
            Button(action: submitForm) {
                Text(mode.buttonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [.brand, .brand.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.6)
        }
        .animation(.easeInOut(duration: 0.2), value: mode)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
    
    // MARK: - Switch Mode
    
    private var switchModeButton: some View {
        HStack(spacing: 4) {
            Text(mode.switchPrompt)
                .foregroundStyle(.secondary)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = mode == .signIn ? .signUp : .signIn
                    errorMessage = nil
                    confirmPassword = ""
                }
            } label: {
                Text(mode.switchAction)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brand)
            }
        }
        .font(.system(size: 14))
        .padding(.top, 8)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Color.appBackground.opacity(0.8)
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .tint(.brand)
                    .scaleEffect(1.2)
            }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8
        
        if mode == .signUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }
    
    // MARK: - Actions
    
    private func submitForm() {
        focusedField = nil
        errorMessage = nil
        
        Task {
            do {
                if mode == .signUp {
                    try await auth.signUp(email: email, password: password)
                } else {
                    try await auth.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = mapError(error)
            }
        }
    }
    
    private func handleGitHub() async {
        errorMessage = nil
        do {
            try await auth.signInWithGitHub()
        } catch {
            errorMessage = mapError(error)
        }
    }
    
    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await auth.signInWithApple(credential: credential)
                } catch {
                    errorMessage = mapError(error)
                }
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = mapError(error)
            }
        }
    }
    
    private func handleGoogle() async {
        errorMessage = nil
        do {
            try await auth.signInWithGoogle()
        } catch {
            let nsError = error as NSError
            if nsError.code != -5 {
                errorMessage = mapError(error)
            }
        }
    }
    
    private func mapError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return "Invalid email or password"
        }
        if message.contains("email not confirmed") {
            return "Please check your email to confirm your account"
        }
        if message.contains("user already registered") {
            return "An account with this email already exists"
        }
        if message.contains("weak password") || message.contains("password") {
            return "Password must be at least 8 characters"
        }
        if message.contains("rate limit") {
            return "Too many attempts. Please try again later"
        }
        if message.contains("network") {
            return "Network error. Please check your connection"
        }
        
        return "Something went wrong. Please try again"
    }
}

// MARK: - Compact Social Button

private struct CompactSocialButton: View {
    let provider: Provider
    let colorScheme: ColorScheme
    let action: () -> Void
    
    enum Provider {
        case apple, google, github
        
        var name: String {
            switch self {
            case .apple: return "Apple"
            case .google: return "Google"
            case .github: return "GitHub"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                iconView
                    .frame(width: 24, height: 24)
                
                Text(provider.name)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch provider {
        case .apple:
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
        case .google:
            GoogleLogo()
        case .github:
            GitHubLogo()
        }
    }
}

// MARK: - GitHub Logo

private struct GitHubLogo: View {
    var body: some View {
        Image(systemName: "chevron.left.forwardslash.chevron.right")
            .resizable()
            .scaledToFit()
            .fontWeight(.semibold)
    }
}

// MARK: - Google Logo

private struct GoogleLogo: View {
    var body: some View {
        ZStack {
            Circle().trim(from: 0.0, to: 0.25).stroke(Color(hex: "4285F4"), lineWidth: 3)
            Circle().trim(from: 0.25, to: 0.5).stroke(Color(hex: "34A853"), lineWidth: 3)
            Circle().trim(from: 0.5, to: 0.75).stroke(Color(hex: "FBBC05"), lineWidth: 3)
            Circle().trim(from: 0.75, to: 1.0).stroke(Color(hex: "EA4335"), lineWidth: 3)
        }
        .rotationEffect(.degrees(-90))
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
        self._emailSent = emailSent
        self._resetEmail = State(initialValue: email)
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        TextField("you@example.com", text: $resetEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        Task {
                            isLoading = true
                            errorMessage = nil
                            do {
                                try await AuthService.shared.resetPassword(email: resetEmail)
                                emailSent = true
                            } catch {
                                errorMessage = "Failed to send reset email"
                            }
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Link")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationBackground(Color.sheetBackground)
    }
}

#Preview {
    LoginView(isPresented: .constant(true))
}
