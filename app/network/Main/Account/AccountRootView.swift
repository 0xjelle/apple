//
//  AccountView.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/12/13.
//

import SwiftUI
import URnetworkSdk

struct AccountRootView: View {
    
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var deviceManager: DeviceManager
    @EnvironmentObject var snackbarManager: UrSnackbarManager
    
    var navigate: (AccountNavigationPath) -> Void
    var logout: () -> Void
    var api: SdkApi
    var totalPayments: Double
    
    @StateObject private var viewModel: ViewModel = ViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    @ObservedObject var referralLinkViewModel: ReferralLinkViewModel
    
    init(
        navigate: @escaping (AccountNavigationPath) -> Void,
        logout: @escaping () -> Void,
        totalPayments: Double,
        api: SdkApi,
        referralLinkViewModel: ReferralLinkViewModel
    ) {
        self.navigate = navigate
        self.logout = logout
        self.api = api
        self.totalPayments = totalPayments
        self.referralLinkViewModel = referralLinkViewModel
    }
    
    
    var body: some View {
        
        let isGuest = deviceManager.parsedJwt?.guestMode ?? true

        VStack {
            
            HStack {
                Text("Account")
                    .font(themeManager.currentTheme.titleFont)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()

                #if os(iOS)
                AccountMenu(
                    isGuest: isGuest,
                    logout: logout,
                    isPresentedCreateAccount: $viewModel.isPresentedCreateAccount,
                    referralLinkViewModel: referralLinkViewModel
                )
                #endif
                
            }
            .frame(height: 32)
            // .padding(.vertical, 12)
            
            Spacer().frame(height: 16)
            
            VStack(spacing: 0) {
                
                HStack {
                    Text("Plan")
                        .font(themeManager.currentTheme.secondaryBodyFont)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    
                    Text(isGuest ? "Guest" : "Free")
                        .font(themeManager.currentTheme.titleCondensedFont)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
  
                    // TODO: add back in when upgrade subscription work complete
//                    Button(action: {
//                        viewModel.isPresentedUpgradeSheet = true
//                    }) {
//                        Text("Create account")
//                            .font(themeManager.currentTheme.secondaryBodyFont)
//                    }
                    
                }
                
                Divider()
                    .background(themeManager.currentTheme.borderBaseColor)
                    .padding(.vertical, 16)
                
                HStack {
                    Text("Network earnings")
                        .font(themeManager.currentTheme.secondaryBodyFont)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline) {
                    
                    Text(totalPayments > 0 ? String(format: "%.4f", totalPayments) : "0")
                        .font(themeManager.currentTheme.titleCondensedFont)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("USDC")
                        .font(themeManager.currentTheme.secondaryBodyFont)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    
                    Spacer()
                    
//                    Button(action: {}) {
//                        Text("Start earning")
//                            .font(themeManager.currentTheme.secondaryBodyFont)
//                    }
                    
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(themeManager.currentTheme.tintedBackgroundBase)
            .cornerRadius(12)
            
            Spacer().frame(height: 16)
            
            /**
             * Navigation items
             */
            VStack(spacing: 0) {
                AccountNavLink(
                    name: "Profile",
                    iconPath: "ur.symbols.user.circle",
                    action: {
                        
                        if isGuest {
                            viewModel.isPresentedCreateAccount = true
                        } else {
                            navigate(.profile)
                        }
                        
                    }
                )
                AccountNavLink(
                    name: "Settings",
                    iconPath: "ur.symbols.sliders",
                    action: {
                        if isGuest {
                            viewModel.isPresentedCreateAccount = true
                        } else {
                            navigate(.settings)
                        }
                    }
                )
                AccountNavLink(
                    name: "Wallet",
                    iconPath: "ur.symbols.wallet",
                    action: {
                        if isGuest {
                            viewModel.isPresentedCreateAccount = true
                        } else {
                            navigate(.wallets)
                        }
                    }
                )
                
                ReferralShareLink(referralLinkViewModel: referralLinkViewModel) {
                    
                    VStack(spacing: 0) {
                        HStack {
                            
                            Image("ur.symbols.heart")
                                .foregroundColor(themeManager.currentTheme.textMutedColor)
                            
                            Spacer().frame(width: 16)
                            
                            Text("Refer friends")
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                            .background(themeManager.currentTheme.borderBaseColor)
                        
                    }
                    
                }
                
                // TODO: desktop will have a different app ID
                Button(action: {
                    openURL(URL(string: "https://apps.apple.com/app/6741000606?action=write-review")!)
                }) {
                    
                    VStack(spacing: 0) {
                        HStack {
                            
                            Image(systemName: "pencil")
                                .foregroundColor(themeManager.currentTheme.textMutedColor)
                                .frame(width: 24)
                            
                            Spacer().frame(width: 16)
                            
                            Text("Review URnetwork")
                                .font(themeManager.currentTheme.bodyFont)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                            .background(themeManager.currentTheme.borderBaseColor)
                        
                    }
                    .contentShape(Rectangle())
                    
                }
                .buttonStyle(.plain)
                
            }
            
            Spacer()
            
            if isGuest {
                UrButton(
                    text: "Create an account",
                    action: {
                        viewModel.isPresentedCreateAccount = true
                    }
                )
            }
            
        }
        .padding()
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .onChange(of: deviceManager.device) {
//            viewModel.isPresentedCreateAccount = false
//        }
        .sheet(isPresented: $viewModel.isPresentedUpgradeSheet) {
            UpgradeSubscriptionSheet(
                subscriptionProduct: subscriptionManager.products.first,
                purchase: { product in
                    subscriptionManager.purchase(
                        product: product,
                        onSuccess: {
                            print("on success called")
                            viewModel.isPresentedUpgradeSheet = false
                        }
                    )
                }
            )
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.isPresentedCreateAccount) {
            LoginNavigationView(
                api: api,
                cancel: {
                    viewModel.isPresentedCreateAccount = false
                },
                
                handleSuccess: { jwt in
                    Task {
                        // viewModel.isPresentedCreateAccount = false
                        await handleSuccessWithJwt(jwt)
                    }
                }
            )
        }
        #endif
    }
    
    private func handleSuccessWithJwt(_ jwt: String) async {
        
        do {
            
            deviceManager.logout()
            
            try await deviceManager.waitUntilDeviceUninitialized()
            
            await deviceManager.initializeNetworkSpace()
            
            try await deviceManager.waitUntilDeviceInitialized()
            
            let result = await deviceManager.authenticateNetworkClient(jwt)
            
            if case .failure(let error) = result {
                print("[AccountRootView] handleSuccessWithJwt: \(error.localizedDescription)")
                
                snackbarManager.showSnackbar(message: "There was an error creating your network. Please try again later.")
                
                return
            }
            
            // TODO: fade out login flow
            // TODO: create navigation view model and switch to main app instead of checking deviceManager.device
            
        } catch {
            print("handleSuccessWithJwt error is \(error)")
        }

        
    }
    
}

private struct AccountNavLink: View {
    
    var name: String
    var iconPath: String
    var action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            
            VStack(spacing: 0) {
                HStack {
                    
                    Image(iconPath)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    
                    Spacer().frame(width: 16)
                    
                    Text(name)
                        .font(themeManager.currentTheme.bodyFont)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    Image("ur.symbols.caret.right")
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    
                }
                // .contentShape(Rectangle())
                .padding(.vertical, 8)
                
                Divider()
                    .background(themeManager.currentTheme.borderBaseColor)
                
            }
            .contentShape(Rectangle())
            
        }
        .buttonStyle(.plain)
        // .contentShape(Rectangle())
        
    }
}

//#Preview {
//    
//    let themeManager = ThemeManager.shared
//    
//    VStack {
//        AccountRootView(
//            navigate: {_ in},
//            logout: {},
//            api: SdkBringYourApi()
//        )
//    }
//    .environmentObject(themeManager)
//    .background(themeManager.currentTheme.backgroundColor)
//    .frame(maxHeight: .infinity)
//    
//}
