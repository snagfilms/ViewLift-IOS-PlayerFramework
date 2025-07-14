//
//  AssetsListViewController+Services.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 08/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation
enum ResponseSource {
    case local
    case server(contentId: String)
}

extension AssetListViewController {
    private func parseEntitlementData(
        from data: Data,apiResponse: @escaping (_ playerObject: VLPlayerLib.PlayerObject?, _ isSuccess: Bool, _ vlError: VLPlayerLib.VLError?, _ playerResponse: VLPlayerLib.VLPlayerResponse?, _ contentResponse: Dictionary<String, AnyObject>?) -> Void
    ) {
        do {
            let responseJson = try JSONSerialization.jsonObject(with: data)
            if let contentResponseDict = responseJson as? Dictionary<String, AnyObject> {
                if contentResponseDict["success"] as? Bool == false {
                    let vlError: VLPlayerLib.VLError = VLPlayerLib.VLError()
                    vlError.errorCode = contentResponseDict["errorCode"] as? String ?? ""
                    vlError.errorMessage = contentResponseDict["errorMessage"] as? String ?? ""
                    vlError.vl_errorCode = contentResponseDict["vl_errorCode"] as? String ?? ""
                    vlError.isPlayable = contentResponseDict["playable"] as? Bool ?? false
                    vlError.isSuccess = contentResponseDict["success"] as? Bool ?? false
                    apiResponse(nil, false, vlError, nil, contentResponseDict)
                } else if let message = contentResponseDict["message"] as? String {
                    let vlError = VLPlayerLib.VLError()
                    if message == "Bad Request" {
                        vlError.errorCode = "Bad Request"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_400"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else if message == "Unauthorized" {
                        vlError.errorCode = "Token Invalid"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_401"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else if message == "Forbidden" {
                        vlError.errorCode = "Forbidden"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_403"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else if message == "OUTSIDE_REGION_LIMIT_REACHED" {
                        vlError.errorCode = "OUTSIDE_REGION_LIMIT_REACHED"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_403"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else if message == "Not Found" {
                        vlError.errorCode = "Not Found"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_404"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else if message == "Request Timeout" {
                        vlError.errorCode = "Request Timeout"
                        vlError.errorMessage = message
                        vlError.vl_errorCode = "VL_408"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    } else {
                        vlError.errorCode = "Network Error"
                        vlError.errorMessage = "Network Error"
                        vlError.vl_errorCode = "VL_Network_Error"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                    }
                    apiResponse(nil, false, vlError, nil, contentResponseDict)
                } else if let code = contentResponseDict["code"] as? String, code.lowercased() == "NETWORK_UNAUTHORIZED".lowercased(){
                    let vlError = VLPlayerLib.VLError()
                    vlError.errorCode = "Network Error"
                    vlError.errorMessage = contentResponseDict["error"] as? String ?? ""
                    vlError.vl_errorCode = code
                    vlError.isPlayable = false
                    vlError.isSuccess = false
                    apiResponse(nil, false, vlError, nil, contentResponseDict)
                }else {
                    let dataParser = DataParser()
                    let playerObject = dataParser.parseContent(channelID: nil, contentDictionary: contentResponseDict)
                    do {
                        let response = try JSONDecoder().decode(VLPlayerResponse.self, from: data)
                        apiResponse(playerObject, true, nil, response, contentResponseDict)
                    } catch {
                        let vlError = VLPlayerLib.VLError()
                        vlError.errorCode = "Not Found"
                        vlError.errorMessage = contentResponseDict["message"] as? String
                        vlError.vl_errorCode = "VL_404"
                        vlError.isPlayable = false
                        vlError.isSuccess = false
                        apiResponse(playerObject, true, nil, nil, contentResponseDict)
                    }
                }
            } else {
                let vlError = VLPlayerLib.VLError()
                vlError.errorCode = ""
                vlError.errorMessage = ""
                vlError.vl_errorCode = ""
                vlError.isPlayable = false
                vlError.isSuccess = false
                apiResponse(nil, false, vlError, nil, nil)
            }
        } catch {
            let vlError = VLPlayerLib.VLError()
            vlError.errorCode = ""
            vlError.errorMessage = ""
            vlError.vl_errorCode = ""
            vlError.isPlayable = false
            vlError.isSuccess = false
            apiResponse(nil, false, vlError, nil, nil)
        }
    }

    func fetchContentDetails(
        source: ResponseSource,
        apiResponse: @escaping (_ playerObject: VLPlayerLib.PlayerObject?, _ isSuccess: Bool, _ vlError: VLPlayerLib.VLError?, _ playerResponse: VLPlayerLib.VLPlayerResponse?, _ contentResponse: Dictionary<String, AnyObject>?) -> Void
    ) {
        switch source {
        case .local:
            guard let fallbackURL = Bundle.main.url(forResource: "entitlement", withExtension: "json"),
                  let localData = try? Data(contentsOf: fallbackURL) else {
                let error = VLPlayerLib.VLError()
                error.errorCode = ""
                error.errorMessage = ""
                error.vl_errorCode = ""
                error.isPlayable = false
                error.isSuccess = false
                apiResponse(nil, false, error, nil, nil)
                return
            }
            parseEntitlementData(from: localData, apiResponse: apiResponse)
        case .server(let contentId):
            let urlString = "\(videoList.partnerApiBaseUrl)/partner/video/assests?id=\(contentId)&site=\(videoList.site)"
            if urlString.contains("xxxxx"){
                self.showAlert(message: "Please update the URL with Api base url and site.\n\(urlString)")
                return
            }
            debugPrint("URL to fetch entitlement data: \(urlString)")
            guard let url = URL(string: urlString) else {
                let error = VLPlayerLib.VLError()
                error.errorCode = ""
                error.errorMessage = ""
                error.vl_errorCode = ""
                error.isPlayable = false
                error.isSuccess = false
                apiResponse(nil, false, error, nil, nil)
                return
            }
            var request = URLRequest(url: url)
            request.setValue(videoList.xApiKey, forHTTPHeaderField: "x-api-key")
            request.httpMethod = "GET"

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    let error = VLPlayerLib.VLError()
                    error.errorCode = ""
                    error.errorMessage = ""
                    error.vl_errorCode = ""
                    error.isPlayable = false
                    error.isSuccess = false
                    apiResponse(nil, false, error, nil, nil)
                    return
                }
                self.parseEntitlementData(from: data, apiResponse: apiResponse)
            }
            task.resume()
        }
    }
}
