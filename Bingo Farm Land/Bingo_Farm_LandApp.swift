//
//  Bingo_Farm_LandApp.swift
//  Bingo Farm Land


import SwiftUI

@main
struct Bingo_Farm_LandApp: App {
    @UIApplicationDelegateAdaptor(BingoFarmAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            BingoFarmGameInitialView()
        }
    }
}
