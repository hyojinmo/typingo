import Foundation

struct Topics {
  enum DailyLife: String, CaseIterable {
    case cafeAndRestaurant
    case atTheStore
    case askingForDirections
    case atTheDoctor
    case phoneCall
    case smallTalk
    case weatherTalk
    
    var title: String {
      switch self {
      case .cafeAndRestaurant:
        "Café & Restaurant 🍽️"
      case .atTheStore:
        "At the Store 🛒"
      case .askingForDirections:
        "Asking for Directions 🧭"
      case .atTheDoctor:
        "At the Doctor 🏥"
      case .phoneCall:
        "Phone Call 📞"
      case .smallTalk:
        "Small Talk ☕"
      case .weatherTalk:
        "Weather Talk 🌦️"
      }
    }
  }
  
  enum Travel: String, CaseIterable {
    case atTheAirport
    case hotelCheckIn
    case orderingATaxi
    case buyingTickets
    case borderImmigration
    
    var title: String {
      switch self {
      case .atTheAirport:
        "At the Airport ✈️"
      case .hotelCheckIn:
        "Hotel Check-in 🏨"
      case .orderingATaxi:
        "Ordering a Taxi 🚕"
      case .buyingTickets:
        "Buying Tickets 🎫"
      case .borderImmigration:
        "Border/Immigration 🛂"
      }
    }
  }
  
  enum SchoolAndWork: String, CaseIterable {
    case classroomTalk
    case presentation
    case jobInterview
    case talkingToAColleague
    
    var title: String {
      switch self {
      case .classroomTalk:
        "Classroom Talk 📚"
      case .presentation:
        "Presentation 💼"
      case .jobInterview:
        "Job Interview 🎤"
      case .talkingToAColleague:
        "Talking to a Colleague 🧑‍💻"
      }
    }
  }
  
  enum AboutMeAndPeople: String, CaseIterable {
    case introducingYourself
    case talkingAboutHobbies
    case talkingAboutFamily
    case makingPlansWithFriends
    
    var title: String {
      switch self {
      case .introducingYourself:
        "Introducing Yourself 👋"
      case .talkingAboutHobbies:
        "Talking about Hobbies 🎨"
      case .talkingAboutFamily:
        "Talking about Family 👨‍👩‍👧"
      case .makingPlansWithFriends:
        "Making Plans with Friends 📅"
      }
    }
  }
  
  enum FeelingsAndReactions: String, CaseIterable {
    case apologizing
    case givingCompliments
    case sayingThankYou
    case cheeringSomeoneUp
    
    var title: String {
      switch self {
      case .apologizing:
        "Apologizing 🙏"
      case .givingCompliments:
        "Giving Compliments 🌟"
      case .sayingThankYou:
        "Saying Thank You 💐"
      case .cheeringSomeoneUp:
        "Cheering Someone Up 💪"
      }
    }
  }
  
  enum FunAndInterests: String, CaseIterable {
    case moviesAndShows
    case musicTalk
    case gamingTalk
    case booksAndReading
    
    var title: String {
      switch self {
      case .moviesAndShows:
        "Movies & Shows 🎬"
      case .musicTalk:
        "Music Talk 🎵"
      case .gamingTalk:
        "Gaming Talk 🎮"
      case .booksAndReading:
        "Books & Reading 📖"
      }
    }
  }
  
  enum Music: String, CaseIterable {
    case kpop
    case jpop
    case cpop
    case pop

    var title: String {
      switch self {
      case .kpop:
        "K-pop 🇰🇷"
      case .jpop:
        "J-pop 🇯🇵"
      case .cpop:
        "C-pop 🇨🇳"
      case .pop:
        "Pop 🌍"
      }
    }

    var artists: [String] {
      switch self {
      case .kpop:
        ["BTS", "BLACKPINK", "NewJeans", "aespa", "Stray Kids",
         "TWICE", "IVE", "(G)I-DLE", "LE SSERAFIM", "SEVENTEEN",
         "EXO", "Red Velvet", "TXT", "ENHYPEN", "ITZY"]
      case .jpop:
        ["YOASOBI", "Ado", "Kenshi Yonezu", "LiSA",
         "Official HIGE DANdism", "Fujii Kaze", "imase", "Vaundy"]
      case .cpop:
        ["Jay Chou", "Eason Chan", "G.E.M.", "Jolin Tsai",
         "JJ Lin", "Stefanie Sun", "Hebe Tien", "Lay Zhang"]
      case .pop:
        ["Taylor Swift", "Ed Sheeran", "The Weeknd", "Billie Eilish",
         "Harry Styles", "Dua Lipa", "Olivia Rodrigo", "Bruno Mars"]
      }
    }
  }

  enum Category: String, CaseIterable {
    case music
    case dailyLife
    case travel
    case schoolAndWork
    case aboutMeAndPeople
    case feelingsAndReactions
    case funAndInterests

    var title: String {
      switch self {
      case .music:
        "🎵 Music & Lyrics"
      case .dailyLife:
        "🌱 Daily Life"
      case .travel:
        "✈️ Travel"
      case .schoolAndWork:
        "🏫 School & Work"
      case .aboutMeAndPeople:
        "🧍 About Me & People"
      case .feelingsAndReactions:
        "🎉 Feelings & Reactions"
      case .funAndInterests:
        "🎮 Fun & Interests"
      }
    }
  }
  
  func presets() -> [String] {
    [
      "KPop",
      "초등학교",
      "친구와 대화",
      "커피숍",
      "여행지",
      "공항",
      "직장생활",
      "iOS 개발자 인터뷰",
    ]
  }
}
