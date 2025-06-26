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
                
                // Main content
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Menu Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Analyze menu photos to discover profit margins and pricing insights")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action button
                Button {
                    print("📊 AnalysisView: Opening menu annotation tool")
                    showingMenuAnnotation = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Open Menu Analysis Tool")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Analysis")
        }
        .sheet(isPresented: $showingMenuAnnotation) {
            MenuAnnotationView(annotationManager: menuAnnotationManager)
        }
    }
}
