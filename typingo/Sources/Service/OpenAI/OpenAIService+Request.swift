import Foundation

extension OpenAIService {
  public struct Request: Sendable, Codable {
    public enum Role: String, Sendable, Codable {
      case system
      case developer
      case user
    }
    
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
      self.role = role
      self.content = content
    }
  }
}
