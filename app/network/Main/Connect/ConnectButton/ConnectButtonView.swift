//
//  ConnectButtonView.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/12/27.
//

import SwiftUI
import URnetworkSdk

struct ConnectButtonView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var deviceManager: DeviceManager
    
    var gridPoints: [SdkId: SdkProviderGridPoint]
    var gridWidth: Int32
    var connectionStatus: ConnectionStatus?
    var windowCurrentSize: Int32
    var connect: () -> Void
    var disconnect: () -> Void
    var connectTunnel: () -> Void
    var contractStatus: SdkContractStatus?
    var openUpgradeSheet: () -> Void
    var currentPlan: Plan
    var isPollingSubscriptionBalance: Bool
    
    @Binding var tunnelConnected: Bool
    
    let canvasWidth: CGFloat = 256
    
    @State var displayReconnectTunnel: Bool = false
    
    var statusMsgIconColor: Color {
        
        if (contractStatus?.insufficientBalance == true && currentPlan == .none) {
            return .urCoral
        } else {
            switch connectionStatus {
                case .disconnected: return .urElectricBlue
                case .connecting: return .urYellow
                case .destinationSet: return .urYellow
                case .connected: return displayReconnectTunnel ? .urCoral : .urGreen
                case .none: return .urElectricBlue
            }
        }
    }
    
    var statusMsg: String {
        
        if (isPollingSubscriptionBalance) {
            return String(localized: "Processing subscription balance...")
        } else if (contractStatus?.insufficientBalance == true && currentPlan == .none) {
            return String(localized: "Insufficient balance")
        } else {
            switch connectionStatus {
            case .disconnected: return String(localized: "Ready to connect")
            case .connecting, .destinationSet: return String(localized: "Connecting to providers")
                case .connected: do {
                    if displayReconnectTunnel {
                        return String(localized: "VPN tunnel disconnected 😓")
                    } else {
                        return String(localized: "Connected to \(windowCurrentSize) providers")
                    }
                }
                case .none: return ""
            }
        }
        
    }
    
    @StateObject private var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        
        VStack {
        
            ZStack {
                
                if (isPollingSubscriptionBalance) {
                    
                    ConnectProcessingSubscriptionView()
                    
                } else if (displayReconnectTunnel || (contractStatus?.insufficientBalance == true && currentPlan == .none)) {
                    
                    ConnectErrorStateView()
                    
                } else {
                 
                    /**
                     * Disconnected
                     */
                    ConnectCanvasDisconnectedStateView()
                        .opacity(connectionStatus == .disconnected ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: connectionStatus)
                    
                    /**
                     * Connecting grid
                     */
                    ConnectCanvasConnectingStateView(gridPoints: gridPoints, gridWidth: gridWidth)
                        .opacity((connectionStatus == .connecting || connectionStatus == .destinationSet)
                            ? 1
                            : 0)
                        .animation(.easeInOut(duration: 0.5), value: connectionStatus)
                    
                    /**
                     * Connected
                     */
                    ConnectCanvasConnectedStateView(
                        canvasWidth: canvasWidth,
                        isActive: connectionStatus == .connected
                        // displayReconnectTunnel: displayReconnectTunnel
                    )
                    
                }
            
                // for capturing tap when disconnected
                Circle()
                    .fill(.clear)
                    .frame(width: canvasWidth, height: canvasWidth)
                    .contentShape(Circle())
                    .onTapGesture {
                        
                        if (connectionStatus == .disconnected &&
                            (contractStatus?.insufficientBalance != true || currentPlan == .supporter) &&
                            !isPollingSubscriptionBalance
                        ) {
                            connect()
                            
#if canImport(UIKit)
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred()
#endif
                            
                        }
                        
                    }
                
            }
            .background(themeManager.currentTheme.tintedBackgroundBase)
            .mask {
                Image("ur.symbols.globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            
            Spacer().frame(height: 32)
            
            HStack {
                
                if connectionStatus != nil {
                    ZStack {
                        Image("GlobeMask")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    .background(statusMsgIconColor)
                }
                
                Spacer().frame(width: 8)
                
                Text(statusMsg)
                    .font(themeManager.currentTheme.bodyFont)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
            }
            
            Spacer().frame(height: 16)
            
            HStack {
                
                if (contractStatus?.insufficientBalance == true && currentPlan != .supporter && !isPollingSubscriptionBalance) {
                    
                    UrButton(
                        text: "Subscribe to fix",
                        action: {
                            openUpgradeSheet()
                            // connectTunnel()
                        },
                        style: .outlineSecondary
                    )
                    
                } else {
                 
                    if (connectionStatus != .disconnected && !displayReconnectTunnel) {

                        UrButton(
                            text: "Disconnect",
                            action: {
                                disconnect()
        #if canImport(UIKit)
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
        #endif
                            },
                            style: .outlineSecondary,
                            enabled: connectionStatus != .disconnected
                        )
                        .animation(.easeInOut(duration: 0.5), value: connectionStatus)
                        
                    }
                    
                    if displayReconnectTunnel {
                        UrButton(
                            text: "Reconnect",
                            action: {
                                
                                connectTunnel()
                                
        #if canImport(UIKit)
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
        #endif
                            },
                            style: .outlineSecondary
                        )
                    }
                    
                }
                
            }
            .frame(width: 192, height: 48)
            
        }
        .padding()
        .onChange(of: connectionStatus) { _ in
            checkTunnelStatus()
        }
        .onChange(of: tunnelConnected) { _ in
            checkTunnelStatus()
        }
        
    }
    
    private func checkTunnelStatus() {
        
        if connectionStatus == .connected && !tunnelConnected {
            self.displayReconnectTunnel = true
        } else {
            self.displayReconnectTunnel = false
        }
        
    }
    
}

#Preview {
    ConnectButtonView(
        gridPoints: [:],
        gridWidth: 16,
        connectionStatus: .disconnected,
        windowCurrentSize: 12,
        connect: {},
        disconnect: {},
        connectTunnel: {},
        openUpgradeSheet: {},
        currentPlan: .supporter,
        isPollingSubscriptionBalance: false,
        tunnelConnected: .constant(true)
    )
}
