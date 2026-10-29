//
//  OneTrustUserDefaults.swift
//  ViewliftPlayerSampleApp
//
//  Copyright © 2026 Viewlift. All rights reserved.
//

import Foundation

final class OneTrustUserDefaultsHelper {

    static let shared = OneTrustUserDefaultsHelper()

    private let defaults = UserDefaults.standard
    private let dictionaryKey = "oneTrustUserDefault"

    private init() {}

    func createOrUpdateValue(forKey key: String, shownConsent value: Bool) {
        var storedDictionary = retrieveDictionary() ?? [:]
        storedDictionary[key] = value
        saveDictionary(storedDictionary)
    }

    func retrieveValue(forKey key: String) -> Bool? {
        guard let storedDictionary = retrieveDictionary() else { return nil }
        return storedDictionary[key]
    }

    func retrieveDictionary() -> [String: Bool]? {
        defaults.dictionary(forKey: dictionaryKey) as? [String: Bool]
    }

    private func saveDictionary(_ dictionary: [String: Bool]) {
        defaults.set(dictionary, forKey: dictionaryKey)
    }
}
