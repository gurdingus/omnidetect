//
//  GoogleAuth.swift
//  VoCAnalyzer
//
//  Created by Codex on 4/19/26.
//

import Foundation
import GoogleSignIn
import Observation
import UIKit

struct GoogleUser: Sendable {
    let name: String
    let email: String
    let pictureURL: URL?
}

@MainActor
@Observable
final class GoogleAuthViewModel {
    var user: GoogleUser?
    var errorMessage: String?
    var isSigningIn = false

    private let authService = GoogleAuthService()

    func signIn() async {
        isSigningIn = true
        errorMessage = nil

        do {
            user = try await authService.signIn()
        } catch GoogleAuthError.cancelled {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isSigningIn = false
    }

    func signOut() {
        authService.signOut()
        user = nil
        errorMessage = nil
    }
}

enum GoogleAuthError: LocalizedError {
    case missingConfiguration
    case missingPresenter
    case cancelled
    case sdk(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Google Sign-In is not configured. Set GoogleOAuthClientID in Info.plist."
        case .missingPresenter:
            return "The app could not find a view controller to present Google Sign-In."
        case .cancelled:
            return "Google sign-in was cancelled."
        case .sdk(let message):
            return message
        }
    }
}

struct GoogleOAuthConfiguration: Sendable {
    let clientID: String

    nonisolated static func load() -> GoogleOAuthConfiguration? {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GoogleOAuthClientID") as? String,
            !clientID.isEmpty,
            !clientID.contains("REPLACE_WITH")
        else {
            return nil
        }

        return GoogleOAuthConfiguration(clientID: clientID)
    }
}

@MainActor
struct GoogleAuthService {
    private let configuration: GoogleOAuthConfiguration?

    init() {
        configuration = GoogleOAuthConfiguration.load()
    }

    func signIn() async throws -> GoogleUser {
        guard let configuration else {
            throw GoogleAuthError.missingConfiguration
        }

        guard let presentingViewController = Self.presentingViewController() else {
            throw GoogleAuthError.missingPresenter
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: configuration.clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let profile = result.user.profile

            return GoogleUser(
                name: profile?.name ?? result.user.profile?.email ?? result.user.userID ?? "Google User",
                email: profile?.email ?? "",
                pictureURL: profile?.imageURL(withDimension: 200)
            )
        } catch let error as NSError {
            if error.domain == kGIDSignInErrorDomain,
               error.code == GIDSignInError.canceled.rawValue {
                throw GoogleAuthError.cancelled
            }

            throw GoogleAuthError.sdk(error.localizedDescription)
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    private static func presentingViewController() -> UIViewController? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        for scene in windowScenes {
            if let rootViewController = scene.windows.first(where: \.isKeyWindow)?.rootViewController {
                return topViewController(from: rootViewController)
            }

            if let rootViewController = scene.windows.first?.rootViewController {
                return topViewController(from: rootViewController)
            }
        }

        return nil
    }

    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let navigationController = root as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topViewController(from: visibleViewController)
        }

        if let tabBarController = root as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(from: selectedViewController)
        }

        if let presentedViewController = root.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return root
    }
}
