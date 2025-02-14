//
//  MainNavigationSplitView.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2025/02/08.
//

import SwiftUI
import URnetworkSdk

enum MainNavigationTab {
    case connect
    case account
    case support
}

#if os(macOS)
struct MainNavigationSplitView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab: MainNavigationTab = .connect
    
    var api: SdkApi
    var device: SdkDeviceRemote
    var logout: () -> Void
    var connectViewController: SdkConnectViewController?
    @Binding var provideWhileDisconnected: Bool
    
    // can probably pass this down from MainView
    @StateObject var providerListSheetViewModel: ProviderListSheetViewModel = ProviderListSheetViewModel()
    
    @StateObject var accountPaymentsViewModel: AccountPaymentsViewModel
    @StateObject var networkUserViewModel: NetworkUserViewModel
    @StateObject var referralLinkViewModel: ReferralLinkViewModel
    
    init(
        api: SdkApi,
        device: SdkDeviceRemote,
        logout: @escaping () -> Void,
        provideWhileDisconnected: Binding<Bool>
    ) {
        self.api = api
        self.logout = logout
        self.device = device
        self._provideWhileDisconnected = provideWhileDisconnected
        self.connectViewController = device.openConnectViewController()

        _accountPaymentsViewModel = StateObject.init(wrappedValue: AccountPaymentsViewModel(
                api: api
            )
        )
        
        _networkUserViewModel = StateObject(wrappedValue: NetworkUserViewModel(api: api))
        
        _referralLinkViewModel = StateObject(wrappedValue: ReferralLinkViewModel(api: api))
    }
    
    var body: some View {
        
        NavigationSplitView {
            List(selection: $selectedTab) {
                
                HStack {

                    Image(selectedTab == .connect ? "ur.symbols.tab.connect.fill" : "ur.symbols.tab.connect")
                        .renderingMode(.template)

                    Text("Connect")
                    
                }
                .foregroundColor(themeManager.currentTheme.textColor)
                .tag(MainNavigationTab.connect)
                
                HStack {
                    
                    Image(selectedTab == .account ? "ur.symbols.tab.account.fill" : "ur.symbols.tab.account")
                        .renderingMode(.template)
                                            
                    Text("Account")
                    
                }
                .foregroundColor(themeManager.currentTheme.textColor)
                .tag(MainNavigationTab.account)
                
                HStack {
                    
                    Image(selectedTab == .support ? "ur.symbols.tab.support.fill" : "ur.symbols.tab.support")
                        .renderingMode(.template)
                    
                    Text("Support")
                    
                }
                .foregroundColor(themeManager.currentTheme.textColor)
                .tag(MainNavigationTab.support)

            }
        }
        detail: {
            
            switch selectedTab {
            case .connect:
                ConnectView_macOS(
                        api: api,
                        logout: logout,
                        device: device,
                        connectViewController: connectViewController
                )
            case .account:
                AccountNavStackView(
                    api: api,
                    device: device,
                    provideWhileDisconnected: $provideWhileDisconnected,
                    logout: logout,
                    accountPaymentsViewModel: accountPaymentsViewModel,
                    networkUserViewModel: networkUserViewModel,
                    referralLinkViewModel: referralLinkViewModel
                )
            case .support:
                FeedbackView(
                    api: api
                )
                .background(themeManager.currentTheme.backgroundColor)
                .tabItem {
                    VStack {
                        Image(selectedTab == .support ? "ur.symbols.tab.support.fill" : "ur.symbols.tab.support")
                            .renderingMode(.template)
                        
                        Text("Support")
                            
                    }
                    .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            
        }
        
    }
}

//#Preview {
//    MainNavigationSplitView()
//}

#endif
