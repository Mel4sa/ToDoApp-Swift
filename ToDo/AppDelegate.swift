//
//  AppDelegate.swift
//  ToDoApp
//
//  Created by Melisa Şimşek on 21.05.2025.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  
      print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as String)
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application did enter background")
    }
    
   
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Application did become active")
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Application will enter foreground")
    }


    func applicationWillTerminate(_ application: UIApplication) {
        print("Application will terminate")
    }

}

