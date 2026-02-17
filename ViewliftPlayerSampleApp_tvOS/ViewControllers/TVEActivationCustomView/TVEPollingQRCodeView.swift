//
//  TVEPollingQRCodeView.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 04/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import SwiftUI
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif

public typealias AuthenticationCallback = (_ userIdentity: VLUserIdentity?, _ errorCode: VLAuthenticationErrorCode?) -> Void

struct TVEPollingQRCodeView: View {
    // MARK: – State & Environment
    @State private var qrImage: Image?
    @State private var activationCode = ""
    @Environment(\.dismiss) private var dismiss
    
    var authCallback: AuthenticationCallback?

    // MARK: – Constants
    private let activateBase =
        "http://spinco.staging.web.viewlift.com/tveactivate?code="

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let qrImage = qrImage {
                VStack {
                    Text("Activation Code: \(activationCode)")
                    
                    Text("Activation URL: \(activateBase + activationCode)")
                    
                    qrImage
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 360, height: 360)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { Task { await setup() } }
        .onDisappear { TVEPollingHelper.shared.stopPolling() }
    }

    // MARK: – Private helpers
    private func setup() async {
        do {
            // 1. Get auth code
            let code = try await VLAuthentication.sharedInstance.generateTVEAuthCode()
            activationCode = code

            // 2. Build full URL & QR
            let url = activateBase + code
            qrImage = TveQRCodeGenerator.generateQRCodeImage(
                from: url, theme: QRCodeTheme(
                    foregroundColor: .red,
                    backgroundColor: .yellow
            ))
            
            // 3. Kick off polling
            TVEPollingHelper.shared.startPolling(
                activationCode: code
            ) { userIdentity in
                self.reloadPlayer(userIdentity: userIdentity)
            } onFailure: { error in
                debugPrint("Polling failed:", error)
                self.authCallback?(nil, error)
            }
            
        } catch VLAuthenticationErrorCode.invalidParameters(let message) {
            debugPrint("Auth-code error: \(message)")
            authCallback?(nil, VLAuthenticationErrorCode.invalidParameters(message: message))
        } catch {
            debugPrint("Auth-code error:", error)
            authCallback?(nil, error as? VLAuthenticationErrorCode ?? VLAuthenticationErrorCode.unknownError(underlyingError: error))
        }
    }

    private func reloadPlayer(userIdentity: VLUserIdentity) {
        // Your existing logic…
        debugPrint("Authenticated for:", userIdentity)
        
        authCallback?(userIdentity, nil)
        
        DispatchQueue.main.async {
            self.dismiss()
        }
        
    }
}
