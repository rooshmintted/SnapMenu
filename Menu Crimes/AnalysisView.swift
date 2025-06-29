//
//  AnalysisView.swift
//  Menu Crimes
//
//  View for menu analysis and annotation features
//

import SwiftUI
import AVKit

struct AnalysisView: View {
    let currentUser: UserProfile
    
    @State private var showingMenuAnnotation = false
    
    // Menu annotation manager for analyzing menu margins
    @State private var menuAnnotationManager = MenuAnnotationManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Premium main content
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Menu AI Analysis")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Discover hidden profit margins, analyze pricing strategies, and unlock menu intelligence with AI-powered insights.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Premium action button
                Button {
                    print("📊 AnalysisView: Opening menu annotation tool")
                    showingMenuAnnotation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .medium))
                        Text("Start AI Analysis")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: showingMenuAnnotation)
                
                Spacer()
            }
            .navigationTitle("Menu Analysis")
        }
        .sheet(isPresented: $showingMenuAnnotation) {
            MenuAnnotationView(annotationManager: menuAnnotationManager)
        }
    }
}
