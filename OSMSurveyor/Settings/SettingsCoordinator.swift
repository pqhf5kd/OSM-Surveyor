//
//  SettingsCoordinator.swift
//  OSMSurveyor
//
//  Created by Wolfgang Timme on 11.04.20.
//  Copyright © 2020 Wolfgang Timme. All rights reserved.
//

import OSMSurveyorFramework
import SafariServices
import UIKit

protocol SettingsCoordinatorProtocol: AnyObject {
    func start()

    /// Starts the flow for adding a new OpenStreetMap account.
    func startAddAccountFlow()

    /// Asks the user whether they want to remove the account with the given `username` from the app.
    /// - Parameters:
    ///   - username: The username of the account the user is about to remove.
    ///   - confirm: Closure that, when executed, will continue with the removal of the account.
    func askForConfirmationToRemoveAccount(username: String,
                                           _ confirm: @escaping () -> Void)

    /// Presents the app's GitHub repository.
    func presentGitHubRepository()

    /// Presents the bug/issue tracker.
    func presentBugTracker()
}

final class SettingsCoordinator {
    // MARK: Private properties

    private let presentingViewController: UIViewController
    private var navigationController: UINavigationController?

    private var addAccountCoordinator: AddAccountFlowCoordinatorProtocol?

    // MARK: Initializer

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
}

extension SettingsCoordinator: SettingsCoordinatorProtocol {
    func start() {
        let viewModel = SettingsViewModel()
        viewModel.coordinator = self

        let settingsViewController = SettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: settingsViewController)

        /// Remember the navigation controller so that we can later use it for other actions.
        self.navigationController = navigationController

        presentingViewController.present(navigationController, animated: true)
    }

    func startAddAccountFlow() {
        guard let navigationController = navigationController else { return }

        guard
            let pathToSecretsPropertyList = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let oAuthHandler = OAuthHandler(propertyListPath: pathToSecretsPropertyList),
            let apiClient = OpenStreetMapAPIClient(propertyListPath: pathToSecretsPropertyList)
        else {
            assertionFailure("Unable to initialize the OAuthHandler")
            return
        }

        let coordinator = AddAccountFlowCoordinator(navigationController: navigationController,
                                                    oAuthHandler: oAuthHandler,
                                                    apiClient: apiClient,
                                                    keychainHandler: KeychainHandler(service: "api.openstreetmap.org"))
        addAccountCoordinator = coordinator

        coordinator.onFinish = { result in
            switch result {
            case let .failure(error):
                let title: String?
                let message: String?
                if case AddAccountFlowCoordinatorError.insufficientPermissions = error {
                    title = "Insufficient privileges"
                    message = "Please allow the app to access ALL OAuth permissions. Do not uncheck the checkboxes! Otherwise, the app will not work properly."
                } else if case KeychainError.usernameAlreadyExists = error {
                    title = "Account already added"
                    message = "An account can only be added once. Please remove the existing one before adding it again."
                } else {
                    title = "Error"
                    message = error.localizedDescription
                }

                let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                navigationController.present(controller, animated: true)
            case let .success(username):
                // TODO: Implement me.
                print("Account added successfully.")
            }
        }

        coordinator.start()
    }

    func askForConfirmationToRemoveAccount(username: String, _ confirm: @escaping () -> Void) {
        let title = "Remove account '\(username)' from the app?"

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
            confirm()
        }
        alertController.addAction(confirmAction)

        navigationController?.present(alertController, animated: true)
    }

    func presentGitHubRepository() {
        guard let url = URL(string: "https://github.com/wtimme/OSM-Surveyor") else { return }

        openExternalURL(url)
    }

    func presentBugTracker() {
        guard let url = URL(string: "https://github.com/wtimme/OSM-Surveyor/issues") else { return }

        openExternalURL(url)
    }

    private func openExternalURL(_ url: URL) {
        let viewController = SFSafariViewController(url: url)
        viewController.modalPresentationStyle = .currentContext

        navigationController?.present(viewController, animated: true)
    }
}
