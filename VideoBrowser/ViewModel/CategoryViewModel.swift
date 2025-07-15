//
//  CategoryViewModel.swift
//  VideoBrowser
//
//  Created by Pankaj Gaikar on 26/08/20.
//  Copyright © 2020 Pankaj Gaikar. All rights reserved.
//

import Foundation
import Combine

/*
 * Custom error class
 * Error triggered will either be network error or parsing error.
 */
enum DataError: Error, LocalizedError {
    case parsing
    
    var errorDescription: String? {
        switch self {
        case .parsing:
            return "Failed to parse data"
        }
    }
}

@MainActor
class CategoryViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var error: DataError?
    @Published var isLoading = false
    
    /*
     * This API fetches the local JSON file data.
     * This API converts the data to Category models array.
     */
    func getCategoriesData() {
        isLoading = true
        error = nil
        
        if let path = Bundle.main.path(forResource: Constants.LocalJSONFile.Name, ofType: Constants.LocalJSONFile.Extension) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let decoder = JSONDecoder()
                self.categories = try decoder.decode([Category].self, from: data)
                self.isLoading = false
            } catch {
                print("parse error: \(error.localizedDescription)")
                self.error = DataError.parsing
                self.isLoading = false
            }
        } else {
            print("Invalid filename/path.")
            self.error = DataError.parsing
            self.isLoading = false
        }
    }
}
