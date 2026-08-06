//
//  SplashView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 6.08.2026.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240, height: 240)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.akorioBg.ignoresSafeArea())
    }
}

#Preview {
    SplashView()
}
