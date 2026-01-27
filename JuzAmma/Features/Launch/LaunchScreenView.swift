//
//  LaunchScreenView.swift
//  JuzAmma
//
//  Created by Febby Rachmat on 17/11/25.
//

import SwiftUI
import SwiftData

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background gradient
            AppColors.brandGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // App Icon
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppConstants.Layout.iconSizeLarge, height: AppConstants.Layout.iconSizeLarge)
                    .cornerRadius(AppConstants.Layout.appIconCornerRadius)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                
                // Bismillah
                Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ")
                    .font(.custom(AppConstants.Fonts.quranArabic, size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // App Name
                Text(AppConstants.appName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Tagline
                Text("Memorize Quran")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Version
                Text("Version \(AppConstants.appVersion)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
        .modelContainer(for: [Surah.self, Ayah.self, AppSettings.self, Translation.self], inMemory: true)
}
