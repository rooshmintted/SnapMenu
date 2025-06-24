//
//  AuthViews.swift
//  Menu Crimes
//
//  Authentication UI components for sign in, sign up, and profile management
//

import SwiftUI

// MARK: - Authentication Container View
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
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("Menu Crimes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            ProgressView()
                .scaleEffect(1.2)
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
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 15) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Menu Crimes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Analyze menus, share with friends")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Sign In Form
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .textFieldStyle(AuthTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(AuthTextFieldStyle())
                    }
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Sign In Button
                    Button(action: signIn) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(25)
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    
                    // Forgot Password
                    Button("Forgot Password?") {
                        showingPasswordReset = true
                    }
                    .font(.footnote)
                    .foregroundColor(.orange)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Sign Up Option
                VStack(spacing: 10) {
                    Text("Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                }
                .padding(.bottom, 30)
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
            VStack(spacing: 25) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
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
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Custom Button Style
struct AuthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    SignInView(authManager: AuthManager())
}
