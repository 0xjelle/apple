//
//  UpgradeSubscriptionSheet.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/12/31.
//

import SwiftUI
import StoreKit

struct UpgradeSubscriptionSheet: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var subscriptionProduct: SKProduct?
    var purchase: (SKProduct) -> Void
    
    var body: some View {
        
        VStack {
            
            if let product = subscriptionProduct {
             
                HStack {
                    
                    Text("Become a")
                        .font(themeManager.currentTheme.titleCondensedFont)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    Text("$\(product.price)/month")
                        .font(themeManager.currentTheme.titleCondensedFont)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    
                }
                
                HStack {
                    Text(product.localizedTitle)
                        .font(themeManager.currentTheme.titleFont)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                }
                
                Spacer().frame(height: 24)
                
                Text("Support us in building a new kind of network that gives instead of takes.")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textMutedColor)
                
                Spacer().frame(height: 18)
                
                Text("You’ll unlock even faster speeds, and first dibs on new features like robust anti-censorship measures and data control.")
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textMutedColor)
                
                Spacer()
                       
                UrButton(text: "Join the movement", action: {
                    // subscriptionManager.purchase(product: product)
                    purchase(product)
                })
                
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
        }
        .padding()
        
    }
}

#Preview {
    
    let themeManager = ThemeManager.shared
    
    let mockProduct = MockSKProduct(
        localizedTitle: "URnetwork Supporter",
        localizedDescription: "Support us in building a new kind of network that gives instead of takes.",
        price: 5.00,
        priceLocale: Locale(identifier: "en_US")
    )
    
    VStack {
        UpgradeSubscriptionSheet(
            subscriptionProduct: mockProduct,
            purchase: {_ in}
        )
    }
    .environmentObject(themeManager)
    .background(themeManager.currentTheme.backgroundColor)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    
}
