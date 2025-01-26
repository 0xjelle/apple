//
//  SettingsViewModel.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/12/10.
//

import Foundation
import URnetworkSdk
import UserNotifications

extension SettingsView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        var api: SdkApi
        
        init(api: SdkApi) {
            self.api = api
            checkNotificationSettings()
        }
        
        @Published var canReceiveNotifications: Bool = false {
            didSet {
                if canReceiveNotifications == true {
                    requestNotificationAuthorization()
                }
            }
        }
        
        /**
         * Delete account
         */
        @Published var isPresentedDeleteAccountConfirmation: Bool = false
        @Published var isDeletingNetwork: Bool = false
        
        let domain = "SettingsViewModel"
        
        private func checkNotificationSettings() {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("Notification permission not determined.")
                case .denied:
                    print("Notification permission denied.")
                case .authorized, .provisional, .ephemeral:
                    print("Notification permission granted.")
                    self.canReceiveNotifications = true
                @unknown default:
                    print("Unknown notification settings.")
                }
            }
        }
        
        private func requestNotificationAuthorization() {
            
            print("requestNotificationAuthorization hit")
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    // Handle the error here.
                    print("Error requesting authorization: \(error.localizedDescription)")
                }
                
                if !granted {
                    print("Notification authorization denied.")
                    DispatchQueue.main.async {
                        self.canReceiveNotifications = false
                    }
                }
            }
            
            
        }
        
        func deleteAccount() async -> Result<Void, Error> {
            
            if isDeletingNetwork {
                return .failure(NetworkDeleteError.inProgress)
            }
            
            DispatchQueue.main.async {
                self.isDeletingNetwork = true
            }
                
            do {
                
                let result: SdkNetworkDeleteResult = try await withCheckedThrowingContinuation { [weak self] continuation in
                
                    guard let self = self else { return }
                    
                    let callback = NetworkDeleteCallback { result, err in
                        
                        if let err = err {
                            continuation.resume(throwing: err)
                            return
                        }
                        
                        guard let result = result else {
                            continuation.resume(throwing: SendPasswordResetLinkError.resultInvalid)
                            return
                        }
                        
                        continuation.resume(returning: result)
                        
                    }
                    
                    api.networkDelete(callback)
                    
                }
                   
                DispatchQueue.main.async {
                    self.isDeletingNetwork = false
                }
                
                return .success(())
                
            }
            catch(let error) {
                DispatchQueue.main.async {
                    self.isDeletingNetwork = false
                }
                return .failure(error)
            }
            
        }
        
    }
    
}

private class NetworkDeleteCallback: SdkCallback<SdkNetworkDeleteResult, SdkNetworkDeleteCallbackProtocol>, SdkNetworkDeleteCallbackProtocol {
    func result(_ result: SdkNetworkDeleteResult?, err: Error?) {
        handleResult(result, err: err)
    }
}

enum NetworkDeleteError: Error {
    case inProgress
    case resultInvalid
}
