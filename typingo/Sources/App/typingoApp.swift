//
//  typingoApp.swift
//  typingo
//
//  Created by HYOJIN MO on 7/11/25.
//

import SwiftUI
import CoreData

@main
struct typingoApp: App {
  @State private var viewContext: NSManagedObjectContext?
  
  var body: some Scene {
    WindowGroup {
      Group {
        if let viewContext {
          ContentView()
            .environment(\.managedObjectContext, viewContext)
        } else {
          ProgressView()
            .controlSize(.large)
            .tint(Color.accentColor.gradient)
        }
      }
      .task {
        viewContext = await AppConfiguration.shared.coreDataManager.viewContext
        
        AppConfiguration.shared.initializeAnalytics()
      }
    }
  }
}
