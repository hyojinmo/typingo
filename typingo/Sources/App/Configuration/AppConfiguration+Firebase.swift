import Firebase

extension AppConfiguration {
  @MainActor
  func initializeAnalytics() {
    #if RELEASE
    FirebaseApp.configure()
    #endif
  }
}
