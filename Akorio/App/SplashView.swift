//
//  SplashView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 6.08.2026.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240, height: 240)
            Text("Akorio")
                .font(.akorioSerif(36, .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AkorioBackground())
    }
}

#Preview {
    SplashView()
}
