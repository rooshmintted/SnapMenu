//
//  AuthViews.swift
//  Menu Crimes
//
//  Authentication UI components for sign in, sign up, and profile management
//

import SwiftUI

// MARK: - Authentication Container View
/// Main authentication container with consistent design system
struct AuthContainerView: View {
    let authManager: AuthManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                SignInView(authManager: authManager)
            case .authenticated:
                // This will be handled by parent view
                EmptyView()
            case .error:
                SignInView(authManager: authManager)
            }
        }
    }
}

// MARK: - Loading View
/// Premium loading screen with brand consistency
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Brand icon with gradient background
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
            .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("Menu AI")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Discover restaurants with intelligence")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Sign In View
struct SignInView: View {
    let authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Premium branding section
                VStack(spacing: 20) {
                    // Brand icon with gradient
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Menu AI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Discover restaurants with intelligence")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 60)
                
                // Modern sign in form
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(ModernTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(ModernTextFieldStyle())
                    }
                    
                    // Error Message with better styling
                    if let errorMessage = authManager.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Premium Sign In Button
                    Button(action: signIn) {
                        HStack(spacing: 8) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    .opacity(authManager.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    // Forgot Password with modern styling
                    Button("Forgot Password?") {
                        showingPasswordReset = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Modern sign up option
                VStack(spacing: 12) {
                    Text("Don't have an account?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button("Create Account") {
                        showingSignUp = true
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
                }
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView(authManager: authManager)
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView(authManager: authManager)
        }
    }
    
    private func signIn() {
        print("🔐 SignInView: Attempting sign in for \(email)")
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    let authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Premium header
                VStack(spacing: 12) {
                    Text("Join Menu AI")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Start discovering restaurants with intelligence")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(AuthTextFieldStyle())
                        .autocapitalization(.none)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(AuthTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(AuthTextFieldStyle())
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(AuthTextFieldStyle())
                }
                
                Button(action: signUp) {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign Up")
                    }
                }
                .buttonStyle(AuthButtonStyle())
                .disabled(!isFormValid || authManager.isLoading)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .foregroundColor(.orange)
                .padding(.top)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .background(Color.black.ignoresSafeArea())
        }
        .navigationBarHidden(true)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        password == confirmPassword && password.count >= 6
    }
    
    private func signUp() {
        print("🔐 SignUpView: Attempting sign up for \(email)")
        Task {
            await authManager.signUp(
                email: email,
                password: password,
                username: username
            )
        }
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    let authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isEmailSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isEmailSent {
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Email Sent!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Check your email for password reset instructions.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Done") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(25)
                        .padding(.horizontal, 40)
                    }
                } else {
                    VStack(spacing: 25) {
                        Text("Reset Password")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Enter your email address and we'll send you instructions to reset your password.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(AuthTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 40)
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: resetPassword) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Email")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(25)
                        .disabled(authManager.isLoading || email.isEmpty)
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func resetPassword() {
        print("🔐 PasswordResetView: Sending reset email to \(email)")
        Task {
            await authManager.resetPassword(email: email)
            if authManager.errorMessage == nil {
                isEmailSent = true
            }
        }
    }
}

// MARK: - Custom Text Field Style
// MARK: - Modern Text Field Style
/// Premium text field design consistent with search interface
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .font(.system(size: 16, weight: .medium))
    }
}

// Legacy style maintained for compatibility
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(ModernTextFieldStyle())
    }
}

// MARK: - Custom Button Style
// MARK: - Modern Button Style
/// Premium button design with gradient and proper states
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Legacy style maintained for compatibility
struct AuthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ModernButtonStyle().makeBody(configuration: configuration)
    }
}

#Preview {
    SignInView(authManager: AuthManager())
}
