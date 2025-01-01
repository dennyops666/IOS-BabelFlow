//
//  IOS_BabelFlowApp.swift
//  IOS-BabelFlow
//
//  Created by Django on 12/25/24.
//

import SwiftUI

@main
struct IOS_BabelFlowApp: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var useCustomAPIKey = KeychainManager.shared.isUsingCustomKey()
    @State private var isLaunching = true
    @State private var logoScale: CGFloat = 0.7
    @State private var textScale: CGFloat = 0.9
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var logoRotation: Double = -30
    @State private var textOffset: CGFloat = 20
    @State private var subtitleOffset: CGFloat = 10
    @State private var glowOpacity: CGFloat = 0
    @State private var pulseScale: CGFloat = 0.8
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: CGFloat = 0.7
    let persistenceController = PersistenceController.shared
    
    init() {
        Task { [self] in
            await testOpenAIKey()
        }
    }
    
    private func testOpenAIKey() async {
        if let apiKey = KeychainManager.shared.getAPIKey() {
            print("Testing OpenAI API Key...")
            let translationService = TranslationService(apiKey: apiKey)
            do {
                let result = try await translationService.translateText("Hello", from: "en", to: "zh")
                print("API Key test successful! Translation result: \(result)")
            } catch {
                print("API Key test failed: \(error)")
            }
        } else {
            print("No API Key available")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if isLaunching {
                        ZStack {
                            // 渐变背景
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.06, green: 0.06, blue: 0.15),
                                    Color(red: 0.03, green: 0.03, blue: 0.08)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .edgesIgnoringSafeArea(.all)
                            
                            // 发光效果背景
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 150
                                    )
                                )
                                .scaleEffect(1.2)
                                .opacity(glowOpacity)
                                .blur(radius: 20)
                            
                            // 波纹动画1
                            Circle()
                                .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2), lineWidth: 2)
                                .scaleEffect(rippleScale)
                                .opacity(rippleOpacity)
                            
                            // 波纹动画2
                            Circle()
                                .stroke(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.15), lineWidth: 3)
                                .scaleEffect(rippleScale * 0.8)
                                .opacity(rippleOpacity)
                            
                            // 脉冲光环
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 80
                                    )
                                )
                                .scaleEffect(pulseScale)
                                .opacity(glowOpacity)
                            
                            VStack(spacing: 16) {
                                // Logo
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 65))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(logoScale)
                                    .rotationEffect(.degrees(logoRotation))
                                    .opacity(logoOpacity)
                                    .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5), radius: 20, x: 0, y: 0)
                                
                                VStack(spacing: 8) {
                                    // App 名称
                                    Text("BabelFlow")
                                        .font(.system(size: 34, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.85)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .offset(y: textOffset)
                                    
                                    // 副标题
                                    Text("Translate with AI")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.gray.opacity(0.9))
                                        .offset(y: subtitleOffset)
                                }
                                .scaleEffect(textScale)
                                .opacity(textOpacity)
                            }
                        }
                        .onAppear {
                            // 发光效果动画
                            withAnimation(.easeIn(duration: 0.8)) {
                                glowOpacity = 1
                            }
                            
                            // Logo 动画
                            withAnimation(
                                .spring(
                                    response: 0.7,
                                    dampingFraction: 0.6,
                                    blendDuration: 0
                                )
                            ) {
                                logoScale = 1.0
                                logoRotation = 0
                            }
                            withAnimation(.easeOut(duration: 0.5)) {
                                logoOpacity = 1
                            }
                            
                            // 文字动画（延迟显示）
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(
                                    .spring(
                                        response: 0.6,
                                        dampingFraction: 0.7,
                                        blendDuration: 0
                                    )
                                ) {
                                    textScale = 1.0
                                    textOffset = 0
                                }
                                withAnimation(.easeOut(duration: 0.5)) {
                                    textOpacity = 1
                                }
                            }
                            
                            // 副标题动画
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(
                                    .spring(
                                        response: 0.5,
                                        dampingFraction: 0.7,
                                        blendDuration: 0
                                    )
                                ) {
                                    subtitleOffset = 0
                                }
                            }
                            
                            // 波纹动画
                            let rippleAnimation = Animation
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: false)
                            
                            withAnimation(rippleAnimation) {
                                rippleScale = 2.0
                                rippleOpacity = 0
                            }
                            
                            // 脉冲动画
                            let pulseAnimation = Animation
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                            
                            withAnimation(pulseAnimation) {
                                pulseScale = 1.2
                            }
                            
                            // 延迟后淡出
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeIn(duration: 0.4)) {
                                    isLaunching = false
                                }
                            }
                        }
                    } else {
                        TabView {
                            NavigationView {
                                ContentView(useCustomAPIKey: $useCustomAPIKey)
                            }
                            .tabItem {
                                Label("Translate", systemImage: "text.bubble")
                            }
                            
                            NavigationView {
                                SettingsView(useCustomAPIKey: $useCustomAPIKey)
                            }
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.colorScheme)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    }
                }
            }
        }
    }
}
