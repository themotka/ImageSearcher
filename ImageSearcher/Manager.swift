//
//  Manager.swift
//  ImageSearcher
//
//  Created by Matthew Widemann on 18.12.2024.
//

import Foundation

final class SearchHistoryManager {
    private let maxHistoryCount = 5
    private let historyKey = "searchHistory"
    
    func saveQuery(_ query: String) {
        var history = getHistory()
        if history.contains(query) { return }
        
        if history.count >= maxHistoryCount {
            history.removeLast()
        }
        
        history.insert(query, at: 0)
        UserDefaults.standard.set(history, forKey: historyKey)
    }
    
    func getHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }
}
