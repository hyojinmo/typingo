import AVFoundation

struct AudioDeviceInteractor {
  func isHeadphonesConnected() -> Bool {
    let audioSession = AVAudioSession.sharedInstance()
    let outputs = audioSession.currentRoute.outputs
    
    for output in outputs {
      switch output.portType {
      case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
        return true
      default:
        continue
      }
    }
    return false
  }
  
  func getSystemVolume() -> Float {
    let audioSession = AVAudioSession.sharedInstance()
    return audioSession.outputVolume
  }
  
  func isVolumeOn() -> Bool {
    return getSystemVolume() > 0.0
  }
}
