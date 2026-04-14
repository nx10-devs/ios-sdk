//
//  KeyboardOnboardingView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 13/04/2026.
//

import SwiftUI

/// Onboarding view component for keyboard integration
/// Sits above the keyboard with clear background, showing welcome message and navigation dots
public struct KeyboardOnboardingView: View {
    
    /// Optional: Custom brain/icon image data
    let iconImage: UIImage?
    
    /// Title text (e.g., "Welcome to NX10")
    let title: String
    
    /// Body/description text
    let pages: [String]
    
    /// Current page index for dots indicator
    let currentPage: Int
    
    /// Optional callback for page indicator tap
    let onPageIndicatorTapped: ((Int) -> Void)?
    
    public init(
        iconImage: UIImage? = nil,
        title: String = "Welcome to NX10",
        pages: [String],
        currentPage: Int = 0,
        onPageIndicatorTapped: ((Int) -> Void)? = nil
    ) {
        self.iconImage = iconImage
        self.title = title
        self.pages = pages
        self.currentPage = currentPage
        self.onPageIndicatorTapped = onPageIndicatorTapped
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Brain icon / Logo
            if let image = iconImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            } else {
                // Default brain emoji
                Text("🧠")
                    .font(.system(size: 32))
                Text("Powered by NX10")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Title
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(2)
            
            // Description
            Text(pages[currentPage])
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.gray)
                .lineLimit(10)
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 8)
            
            // Page indicator dots
            if pages.count > 1 {
                Divider().frame(height: 1)
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        PageIndicatorDot(
                            isActive: index == currentPage,
                            onTap: {
                                onPageIndicatorTapped?(index)
                            }
                        )
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)  // ✅ Clear background for keyboard integration
    }
}

// MARK: - Page Indicator Dot

private struct PageIndicatorDot: View {
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.white : Color.gray.opacity(0.5))
            .frame(width: 8, height: 8)
            .onTapGesture(perform: onTap)
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    KeyboardOnboardingView(
        title: "Welcome to NX10",
        pages: ["Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", "Stuff"],
        currentPage: 0,
        onPageIndicatorTapped: { page in
            print("Tapped page: \(page)")
        }
    )
    .background(Color.black)  // Preview with dark background to simulate keyboard
    .padding()
}
