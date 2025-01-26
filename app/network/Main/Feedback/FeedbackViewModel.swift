//
//  FeedbackViewModel.swift
//  URnetwork
//
//  Created by Stuart Kuentzel on 2024/12/10.
//

import Foundation
import URnetworkSdk

enum SendFeedbackError: Error {
    case isSending
    case emptyResult
    case invalidArgs
}

private class SendFeedbackCallback: SdkCallback<SdkFeedbackSendResult, SdkSendFeedbackCallbackProtocol>, SdkSendFeedbackCallbackProtocol {
    func result(_ result: SdkFeedbackSendResult?, err: Error?) {
        handleResult(result, err: err)
    }
}

extension FeedbackView {
    
    @MainActor
    class ViewModel: ObservableObject {
        
        @Published var feedback: String = ""
        @Published private(set) var isSending: Bool = false
        let domain = "[FeedbackViewModel]"
        
        var api: SdkApi?
        
        init(api: SdkApi?) {
            self.api = api
        }
        
        func sendFeedback() async -> Result<Void, Error> {
            
            if isSending {
                return .failure(SendFeedbackError.isSending)
            }
            
            do {
                
                let result: SdkFeedbackSendResult = try await withCheckedThrowingContinuation { [weak self] continuation in
                    
                    guard let self = self else { return }
                    
                    let callback = SendFeedbackCallback { result, err in
                        
                        if let err = err {
                            continuation.resume(throwing: err)
                            return
                        }
                        
                        guard let result else {
                            continuation.resume(throwing: SendFeedbackError.emptyResult)
                            return
                        }
                        
                        continuation.resume(returning: result)
                        
                    }
                    
                    let args = SdkFeedbackSendArgs()
                    let needs = SdkFeedbackSendNeeds()
                    needs.other = feedback
                    args.needs = needs
                    
                    api?.sendFeedback(args, callback: callback)
                    
                }
                
                feedback = ""
                
                return .success(())
                
                
            } catch(let error) {
                print("\(domain) Error sending feedback: \(error)")
                return .failure(error)
            }
            
        }
        
    }
    
}
