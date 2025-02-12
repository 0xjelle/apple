//
//  LoginInitialView.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/11/20.
//

import SwiftUI
import URnetworkSdk
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn

struct LoginInitialView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var snackbarManager: UrSnackbarManager
    @EnvironmentObject var deviceManager: DeviceManager
    @StateObject private var viewModel: ViewModel
    @State private var initialIsLandscape: Bool = false
    
    @ObservedObject var guestUpgradeViewModel: GuestUpgradeViewModel
    
    var api: SdkApi?
    var navigate: (LoginInitialNavigationPath) -> Void
    var cancel: (() -> Void)?
    var handleSuccess: (_ jwt: String) async -> Void
    
    init(
        api: SdkApi?,
        navigate: @escaping (LoginInitialNavigationPath) -> Void,
        cancel: (() -> Void)? = nil,
        handleSuccess: @escaping (_ jwt: String) async -> Void,
        guestUpgradeViewModel: GuestUpgradeViewModel
    ) {
        _viewModel = StateObject(wrappedValue: ViewModel(api: api))
        self.navigate = navigate
        self.cancel = cancel
        self.handleSuccess = handleSuccess
        self.guestUpgradeViewModel = guestUpgradeViewModel
    }
    
    var body: some View {
        
        let deviceExists = deviceManager.device != nil
        
        GeometryReader { geometry in
            
            #if os(iOS)
            let isTablet = UIDevice.current.userInterfaceIdiom == .pad
            #else
            let isTablet = false
            #endif
      
            ScrollView {
                
                if initialIsLandscape && isTablet {
                    
                    HStack(alignment: .center) {
                        
                        LoginCarousel()
                            .frame(width: geometry.size.width / 2)
                        
                        LoginInitialFormView(
                            userAuth: $viewModel.userAuth,
                            handleUserAuth: handleUserAuth,
                            handleAppleLoginResult: handleAppleLoginResult,
                            handleGoogleSignInButton: handleGoogleSignInButton,
                            isValidUserAuth: viewModel.isValidUserAuth,
                            isCheckingUserAuth: viewModel.isCheckingUserAuth,
                            deviceExists: deviceExists,
                            presentGuestNetworkSheet: $viewModel.presentGuestNetworkSheet
                        )
                        .frame(width: geometry.size.width / 2, alignment: .leading)
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center) // Fill the height and center content
                    
                } else {
                
                    VStack {
                        
                        LoginCarousel()
                        
                        Spacer().frame(height: 64)
                        
                        LoginInitialFormView(
                            userAuth: $viewModel.userAuth,
                            handleUserAuth: handleUserAuth,
                            handleAppleLoginResult: handleAppleLoginResult,
                            handleGoogleSignInButton: handleGoogleSignInButton,
                            isValidUserAuth: viewModel.isValidUserAuth,
                            isCheckingUserAuth: viewModel.isCheckingUserAuth,
                            deviceExists: deviceExists,
                            presentGuestNetworkSheet: $viewModel.presentGuestNetworkSheet
                        )
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                    
                }
                
            }
            .sheet(isPresented: $viewModel.presentGuestNetworkSheet) {
                
                GuestModeSheet(
                    termsAgreed: $viewModel.termsAgreed,
                    isCreatingGuestNetwork: viewModel.isCreatingGuestNetwork,
                    onCreateGuestNetwork: {
                        Task {
                            let result = await viewModel.createGuestNetwork()
                            await self.handleCreateGuestNetworkResult(result)
                        }
                    }
                )
                .presentationDetents([.height(264)])
                
            }
            .scrollIndicators(.hidden)
            .toolbar {
                if let cancel = cancel {
                    
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        
                        Button(action: { cancel() }) {
                            Image(systemName: "xmark")
                        }
                        
                    }
                    #elseif os(macOS)
                    ToolbarItem {
                        
                        Button(action: { cancel() }) {
                            Image(systemName: "xmark")
                        }
                        
                    }
                    #endif
                    
                    ToolbarItem(placement: .principal) {
                        Text("Create Account")
                            .font(themeManager.currentTheme.toolbarTitleFont).fontWeight(.bold)
                    }
                }
            }
        }
        .onAppear {
            // Cache initial orientation
            #if os(iOS)
            let orientation = UIDevice.current.orientation
            initialIsLandscape = orientation.isLandscape
            #elseif os(macOS)
            initialIsLandscape = true
            #endif
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Only update on actual rotation events
            let orientation = UIDevice.current.orientation
            if orientation.isValidInterfaceOrientation {
                initialIsLandscape = orientation.isLandscape
            }
        }
        #endif
        
    }
    
    private func handleCreateGuestNetworkResult(_ result: LoginNetworkResult) async {
        switch result {
            
        case .successWithJwt(let jwt):
            viewModel.presentGuestNetworkSheet = false
            await handleSuccess(jwt)
            break
        case .failure(let error):
            print("CreateNetworkView: handleResult: \(error.localizedDescription)")
            break
        default:
            print("neither success with jwt or failure")
            break
            
        }
    }
    
    private func handleAppleLoginResult(_ result: Result<ASAuthorization, any Error>) async {

        let createArgsResult = viewModel.createAppleAuthLoginArgs(result)
        switch createArgsResult {
        case .success(let args):
            
            if deviceManager.device != nil {
        
                // device exists, meaning we're in the guest flow
                // link guest account to google account
                
                let upgradeArgs = self.createUpgradeExistingSocialArgs(args)
                
                let result = await guestUpgradeViewModel.linkGuestToExistingLogin(args: upgradeArgs)
                await self.handleAuthLoginResult(result)
                
            } else {
             
                // login with apple
                // let result = await viewModel.authLogin(args: args)
                let result = await viewModel.authLogin(args: args)
                await self.handleAuthLoginResult(result)
                
            }
        
        case .failure(let error):
            print("error create args result: \(error.localizedDescription)")
            snackbarManager.showSnackbar(message: "There was an error logging in")
        }
        
     }
    
    
    private func handleUserAuth() async {
        
        let createArgsResult = viewModel.getStarted()
        switch createArgsResult {
        case .success(let args):
            
            let result = await viewModel.authLogin(args: args)
            await self.handleAuthLoginResult(result)
        
        case .failure(let error):
            print("error create args result: \(error.localizedDescription)")
            snackbarManager.showSnackbar(message: "There was an error logging in")
        }
        
    }
    
    private func handleAuthLoginResult(_ authLoginResult: AuthLoginResult) async {
        
        switch authLoginResult {
            
        case .login(let authJwt):
            
            await handleSuccess(authJwt)
            
            break
            
        case .promptPassword(let loginResult):
            navigate(.password(loginResult.userAuth))
            break
            
        case .create(let authLoginArgs):
            navigate(.createNetwork(authLoginArgs))
            break

        // verificationRequired should not be hit from this view
        case .verificationRequired(let userAuth):
            print("verificationRequired should not be hit from this view")
            navigate(.verify(userAuth))
            break
        
        case .failure(let error):
            print("auth login error: \(error.localizedDescription)")
            viewModel.setIsCheckingUserAuth(false)
            break
            
        }
    }
    
    private func createUpgradeExistingSocialArgs(_ args: SdkAuthLoginArgs) -> SdkUpgradeGuestExistingArgs {
        let updateArgs = SdkUpgradeGuestExistingArgs()
        updateArgs.authJwt = args.authJwt
        updateArgs.authJwtType = args.authJwtType
        return updateArgs
    }
    
    private func handleGoogleSignInButton() async {
        
        #if os(iOS)
        guard let rootViewController = getRootViewController() else {
            print("no root view controller found")
            return
        }
        
        do {
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            let createArgsResult = viewModel.createGoogleAuthLoginArgs(signInResult)
            switch createArgsResult {
            case .success(let args):
                
                if deviceManager.device != nil {
            
                    // device exists, meaning we're in the guest flow
                    // link guest account to google account
                    // let result = await viewModel.linkGuestToExistingSocialLogin(args: args)
                    
                    let upgradeArgs = self.createUpgradeExistingSocialArgs(args)
                    
                    let result = await guestUpgradeViewModel.linkGuestToExistingLogin(args: upgradeArgs)
                    
                    await self.handleAuthLoginResult(result)
                    
                } else {
                 
                    // login with google
                    let result = await viewModel.authLogin(args: args)
                    await self.handleAuthLoginResult(result)
                    
                }
            
            case .failure(let error):
                print("error create args result: \(error.localizedDescription)")
                snackbarManager.showSnackbar(message: "There was an error logging in")
            }
            
         } catch {
             print("Error signing in: \(error.localizedDescription)")
             snackbarManager.showSnackbar(message: "There was an error logging in")
         }
        
        #endif
        
    }
    
}

private struct LoginInitialFormView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var userAuth: String
    var handleUserAuth: () async -> Void
    var handleAppleLoginResult: (_ result: Result<ASAuthorization, any Error>) async -> Void
    var handleGoogleSignInButton: () async -> Void
    var isValidUserAuth: Bool
    var isCheckingUserAuth: Bool
    var deviceExists: Bool
    // var isGuestMode: Bool
    
    @Binding var presentGuestNetworkSheet: Bool
    
    var body: some View {
        
        VStack {
         
            #if os(iOS)
            UrTextField(
                text: $userAuth,
                label: "Email or phone number",
                placeholder: "Enter your phone number or email",
                onTextChange: { newValue in
                    // Filter whitespace
                    if newValue.contains(" ") {
                        userAuth = newValue.filter { !$0.isWhitespace }
                    }
                },
                keyboardType: .emailAddress,
                submitLabel: .continue,
                onSubmit: {
                 
                    Task {
                        await handleUserAuth()
                    }
                    
                }
            )
            #elseif os(macOS)
            UrTextField(
                text: $userAuth,
                label: "Email or phone number",
                placeholder: "Enter your phone number or email",
                onTextChange: { newValue in
                    // Filter whitespace
                    if newValue.contains(" ") {
                        userAuth = newValue.filter { !$0.isWhitespace }
                    }
                },
                submitLabel: .continue,
                onSubmit: {
                 
                    Task {
                        await handleUserAuth()
                    }
                    
                }
            )
            #endif
            
            Spacer()
                .frame(height: 32)
            
            UrButton(
                text: "Get started",
                action: {
                    Task {
                        await handleUserAuth()
                    }
                },
                enabled: isValidUserAuth && !isCheckingUserAuth,
                isProcessing: isCheckingUserAuth
            )
            
            Spacer()
                .frame(height: 24)
            
            Text("or", comment: "Referring to the two options 'Get started' *or* 'Login with Apple'")
                .foregroundColor(themeManager.currentTheme.textMutedColor)
            
            Spacer()
                .frame(height: 24)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                
                print("SignInWithAppleButton: onCompletion")
                
                Task {
                    await handleAppleLoginResult(result)
                }
            }
            .frame(height: 48)
            .clipShape(Capsule())
            .signInWithAppleButtonStyle(.white)
            
            Spacer()
                .frame(height: 24)
            
            UrGoogleSignInButton(
                action: handleGoogleSignInButton
            )
            
            Spacer()
                .frame(height: 24)
            
            if !deviceExists {
                // if a device exists, it means they are already in guest mode and trying to upgrade their account
                // restrict access to create guest network from within authed guest network
             
                HStack {
                    Text("Commitment issues?")
                        .font(themeManager.currentTheme.bodyFont)
                        .foregroundColor(themeManager.currentTheme.textMutedColor)
                    
                    Button(action: {
                        presentGuestNetworkSheet = true
                    }) {
                        Text("Try Guest Mode")
                            .font(themeManager.currentTheme.bodyFont)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                }
                
            }
            
        }
        .frame(maxWidth: 400)
    }
}

//#Preview {
//    ZStack {
//        LoginInitialView(
//            api: nil,
//            navigate: {_ in },
//            handleSuccess: {_ in },
//        )
//    }
//    .environmentObject(ThemeManager.shared)
//    .background(ThemeManager.shared.currentTheme.backgroundColor)
//}
