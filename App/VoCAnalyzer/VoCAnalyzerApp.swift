//
//  VoCAnalyzerApp.swift
//  VoCAnalyzer
//
//  Created by Vaishnavi Sannidhanam on 4/19/26.
//

import GoogleSignIn
import SwiftUI

@main
struct VoCAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
