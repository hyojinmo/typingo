import Foundation

struct LyricsService: Sendable {
  struct SearchResult: Sendable, Codable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let plainLyrics: String?
    let syncedLyrics: String?
  }

  private let baseURL = "https://lrclib.net/api"

  func search(query: String) async throws -> [SearchResult] {
    guard var components = URLComponents(string: "\(baseURL)/search") else {
      throw URLError(.badURL)
    }
    components.queryItems = [URLQueryItem(name: "q", value: query)]

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.setValue("Typingo/1.0", forHTTPHeaderField: "User-Agent")

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([SearchResult].self, from: data)
  }

  func fetchContent(
    query: String,
    nativeLanguage: String,
    targetLanguage: String
  ) async throws -> TypingoService.Response {
    let results = try await search(query: query)

    guard let track = results.first(where: { $0.plainLyrics != nil && !$0.plainLyrics!.isEmpty }) else {
      throw LyricsError.noLyricsFound
    }

    let verses = splitVerses(track.plainLyrics ?? "")

    let scripts = verses.map { verse in
      TypingoService.Response.Script(
        speaker: "🎤 \(track.artistName)",
        target: verse,
        native: ""
      )
    }

    let nextTopics = suggestNextTopics(excluding: query)

    return TypingoService.Response(
      category: "lyrics:\(query)",
      level: "",
      nativeLanguage: nativeLanguage,
      targetLanguage: targetLanguage,
      title: "🎵 \(track.trackName)",
      subtitle: .init(
        target: track.artistName,
        native: track.artistName
      ),
      script: scripts,
      keyExpressions: [],
      nextTopics: nextTopics,
      motivation: .init(
        speaker: "🎵",
        target: "",
        native: ""
      )
    )
  }

  private func splitVerses(_ lyrics: String) -> [String] {
    let rawSections = lyrics.components(separatedBy: "\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard !rawSections.isEmpty else { return [lyrics] }

    var merged: [String] = []
    var buffer = ""

    for section in rawSections {
      let lineCount = section.components(separatedBy: "\n").count
      if buffer.isEmpty {
        if lineCount < 2 {
          buffer = section
        } else {
          merged.append(section)
        }
      } else {
        buffer += "\n\n" + section
        let bufferLineCount = buffer.components(separatedBy: "\n").count
        if bufferLineCount >= 2 {
          merged.append(buffer)
          buffer = ""
        }
      }
    }

    if !buffer.isEmpty {
      if let last = merged.last {
        merged[merged.count - 1] = last + "\n\n" + buffer
      } else {
        merged.append(buffer)
      }
    }

    if merged.count > 8 {
      return Array(merged.prefix(8))
    }

    return merged
  }

  private static let popularArtists = [
    "BTS", "BLACKPINK", "NewJeans", "aespa", "Stray Kids",
    "TWICE", "IVE", "(G)I-DLE", "LE SSERAFIM", "SEVENTEEN",
    "EXO", "Red Velvet", "TXT", "ENHYPEN", "ITZY",
    "YOASOBI", "Ado", "Kenshi Yonezu", "LiSA", "Official HIGE DANdism",
    "Jay Chou", "Eason Chan", "G.E.M.", "Jolin Tsai",
    "Taylor Swift", "Ed Sheeran", "The Weeknd", "Billie Eilish"
  ]

  private func suggestNextTopics(excluding current: String) -> [String] {
    let filtered = Self.popularArtists.filter {
      $0.lowercased() != current.lowercased()
    }
    let shuffled = filtered.shuffled()
    return Array(shuffled.prefix(4)).map { "lyrics:\($0)" }
  }

  enum LyricsError: LocalizedError {
    case noLyricsFound

    var errorDescription: String? {
      switch self {
      case .noLyricsFound:
        return "No lyrics found for this search."
      }
    }
  }
}
