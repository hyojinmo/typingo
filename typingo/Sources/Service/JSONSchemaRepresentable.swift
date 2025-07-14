// https://json-schema.org
// https://spec.openapis.org/oas/v3.0.3

import Foundation

public protocol JSONSchemaRepresentable: Sendable, Codable {
  static func reflectMirroring() -> Self
}

extension JSONSchemaRepresentable {
  func jsonSchema() -> [String: Any] {
    var components: [String: [String: Any]] = [:]
    return createRecursiveSchema(components: &components)
  }
  
  private func createRecursiveSchema(components: inout [String: [String: Any]]) -> [String: Any] {
    let typeName = String(describing: type(of: self))
    if let _ = components[typeName] {
      return ["$ref": "#/components/schemas/\(typeName)"]
    }
    
    let mirror = Mirror(reflecting: self)
    var properties: [String: Any] = [:]
    var requiredFields: [String] = []
    
    components[typeName] = ["type": "object"]
    
    for child in mirror.children {
      if let label = child.label {
        let type = Swift.type(of: child.value)
        let schema = mapSwiftTypeToSchema(type, value: child.value, components: &components)
        properties[label] = schema
        if !isOptional(type) {
          requiredFields.append(label)
        }
      }
    }
    
    var schema: [String: Any] = ["type": "object", "properties": properties]
    if !requiredFields.isEmpty {
      schema["required"] = requiredFields
    }
    
    components[typeName] = schema
    return schema
  }
  
  private func mapSwiftTypeToSchema(_ type: Any.Type, value: Any, components: inout [String: [String: Any]]) -> [String: Any] {
    let typeString = String(describing: type)
    
    if isOptional(type) {
      let innerType = unwrapOptionalType(typeString)
      var schema = mapSwiftTypeToSchema(innerType, value: value, components: &components)
      schema["nullable"] = true
      return schema
    }
    
    if isArray(type) {
      let itemType = unwrapArrayType(typeString)
      return ["type": "array", "items": mapSwiftTypeToSchema(itemType, value: (value as? [Any])?.first ?? "", components: &components)]
    }
    
    if let enumType = type as? any CaseIterable.Type {
      return ["type": "string", "enum": enumType.allCases.map { "\($0)" }]
    }
    
    if let obj = value as? JSONSchemaRepresentable {
      return obj.createRecursiveSchema(components: &components)
    }
    
    return mapPrimitiveType(typeString)
  }
  
  private func isOptional(_ type: Any.Type) -> Bool {
    return String(describing: type).contains("Optional")
  }
  
  private func isArray(_ type: Any.Type) -> Bool {
    return String(describing: type).contains("Array")
  }
  
  private func unwrapOptionalType(_ typeString: String) -> Any.Type {
    let innerTypeString = typeString.replacingOccurrences(of: "Optional<", with: "").dropLast()
    if innerTypeString.hasPrefix("Array") {
      switch innerTypeString {
      case "String": return Array<String>.self
      case "Int": return Array<Int>.self
      case "Double": return Array<Double>.self
      case "Float": return Array<Float>.self
      case "Bool": return Array<Bool>.self
      case "Date": return Array<Date>.self
      default: return Array<String>.self
      }
    }
    switch innerTypeString {
    case "String": return String.self
    case "Int": return Int.self
    case "Double": return Double.self
    case "Float": return Float.self
    case "Bool": return Bool.self
    case "Date": return Date.self
    default: return String.self
    }
  }
  
  private func unwrapArrayType(_ typeString: String) -> Any.Type {
    let innerTypeString = typeString.replacingOccurrences(of: "Array<", with: "").dropLast()
    switch innerTypeString {
    case "String": return String.self
    case "Int": return Int.self
    case "Double": return Double.self
    case "Float": return Float.self
    case "Bool": return Bool.self
    case "Date": return Date.self
    default: return String.self
    }
  }
  
  private func mapPrimitiveType(_ typeString: String) -> [String: Any] {
    switch typeString {
    case _ where typeString.contains("String"): return ["type": "string"]
    case _ where typeString.contains("Int"): return ["type": "integer", "format": "int64"]
    case _ where typeString.contains("Double") || typeString.contains("Float"): return ["type": "number", "format": "double"]
    case _ where typeString.contains("Bool"): return ["type": "boolean"]
    case _ where typeString.contains("Date"): return ["type": "string", "format": "date-time"]
    default: return ["type": "object"]
    }
  }
}
