//
//  AppDelegate.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 03.04.2024.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var shared:AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }
    
    var presentingWindowID:String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillResignActive(_ application: UIApplication) {
        let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        navigationController?.viewControllers.forEach({
            if let vc = $0 as? TabBarController {
                vc.applicationWillResignActive()
            }
        })
    }
}

