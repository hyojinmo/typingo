extension String {
  static func flag(country:String) -> String {
    let base : UInt32 = 127397
    var s = ""
    for v in country.unicodeScalars {
      s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
    }
    return String(s)
  }
  
  func flagEmoji() -> String {
    return String.flag(country: self)
  }
}
