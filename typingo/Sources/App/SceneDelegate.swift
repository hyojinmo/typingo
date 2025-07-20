import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    handleShortcutItem(shortcutItem)
    completionHandler(true)
  }
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let shortcutItem = connectionOptions.shortcutItem {
      handleShortcutItem(shortcutItem)
    }
  }
  
  private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
    if shortcutItem.type == "StartLesson" {
      
    }
  }
}
