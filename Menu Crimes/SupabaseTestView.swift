//
//  SupabaseTestView.swift
//  Menu Crimes
//
//  Simple test view to verify Supabase connection
//

import SwiftUI

struct SupabaseTestView: View {
    @State private var testResult = "Testing..."
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Supabase Connection Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text(testResult)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button("Test Connection") {
                    testSupabaseConnection()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(10)
            }
            
            Button("Test Sign Up") {
                testSignUp()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .disabled(isLoading)
        }
        .padding()
    }
    
    private func testSupabaseConnection() {
        isLoading = true
        testResult = "Testing connection..."
        
        Task {
            do {
                // Test basic connection by trying to get auth session
                let session = try await supabase.auth.session
                await MainActor.run {
                    testResult = "✅ Connection successful! User ID: \(session.user.id)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("Auth session missing") {
                        testResult = "✅ Connection successful! (No active session, which is expected)"
                    } else {
                        testResult = "❌ Connection failed: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func testSignUp() {
        isLoading = true
        testResult = "Testing sign up..."
        
        Task {
            do {
                let testEmail = "test\(Int.random(in: 1000...9999))@example.com"
                let testPassword = "testpassword123"
                
                print("🧪 Testing signup with email: \(testEmail)")
                
                let authResponse = try await supabase.auth.signUp(
                    email: testEmail,
                    password: testPassword
                )
                
                await MainActor.run {
                    let user = authResponse.user
                    if authResponse.session != nil {
                        testResult = "✅ Sign up successful! User ID: \(user.id)"
                    } else {
                        testResult = "📧 Sign up successful! Email confirmation required for: \(user.id)"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Sign up failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SupabaseTestView()
}
