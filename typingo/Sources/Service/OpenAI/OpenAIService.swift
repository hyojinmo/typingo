import Foundation

// https://platform.openai.com/docs/guides/text-generation#quickstart

struct OpenAIService: Sendable {
  enum GPTModel: String, Codable {
    case gpt4oMini = "gpt-4o-mini"
    case gpt4o = "gpt-4o"
    case gpt41nano = "gpt-4.1-nano"
    case gpt41mini = "gpt-4.1-mini"
    case gpt41 = "gpt-4.1"
  }
  
  private let apiKey: String = Bundle.main.infoDictionary!["OPEN_AI_SECRET"] as! String
  
  enum ChatCompletionResponse: Sendable {
    struct Choice: Sendable, Codable {
      struct Message: Sendable, Codable {
        let content: String
      }
      let message: Message
    }
    
    struct Response: Sendable, Codable {
      let choices: [Choice]
    }
  }
  
  func chat<T: JSONSchemaRepresentable>(
    messages: [Request],
    model: GPTModel = .gpt4oMini,
    store: Bool = false
  ) async throws -> T {
    let api = "https://api.openai.com/v1/chat/completions"
    let url = URL(string: api)!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let requestBody: [String: Any] = [
      "model": model.rawValue,
      "messages": messages.map {
        [
          "role": $0.role.rawValue,
          "content": $0.content
        ]
      },
      "response_format": [
        "type": "json_schema",
        "json_schema": [
          "name": "scheduling",
          "schema":  T
            .reflectMirroring()
            .jsonSchema()
        ]
      ]
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
    request.httpBody = jsonData
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(
        .badServerResponse
      )
    }
    
    if httpResponse.statusCode == 200 {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      
      let response = try decoder.decode(ChatCompletionResponse.Response.self, from: data)
      if let choice = response.choices.first,
         let messageData = choice.message.content.data(using: .utf8)
      {
        return try decoder.decode(T.self, from: messageData)
      } else {
        throw Error.invalidChatResponse
      }
    } else {
      let errorResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
      let errorInfo = errorResponse["error"] as? [String: Any] ?? [:]
      throw NSError(
        domain: "OpenAI",
        code: httpResponse.statusCode,
        userInfo: [
          "code": errorInfo["code"] ?? "",
          "message": errorInfo["message"] ?? "",
          "type": errorInfo["type"] ?? "",
        ]
      )
    }
  }
}

// TODO: 에러 처리
// Error Domain=OpenAI Code=429 "(null)" UserInfo={message=Rate limit reached for gpt-4o-mini in organization org-9r3eyo56Zrxh16pfBEnXIh1u on tokens per min (TPM): Limit 100000, Used 99857, Requested 1297. Please try again in 8h18m31.68s. Visit https://platform.openai.com/account/rate-limits to learn more., type=tokens, code=rate_limit_exceeded}
