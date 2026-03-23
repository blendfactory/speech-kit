import Darwin
import Foundation
import CoreMedia
import AVFAudio
import Speech

private func dupCString(_ s: String) -> UnsafeMutablePointer<CChar>? {
  s.withCString { strdup($0) }
}

@available(macOS 26.0, *)
private func parseModules(data: Data) throws -> [any SpeechModule] {
  guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid JSON root (expected array of objects)"],
    )
  }
  var out: [any SpeechModule] = []
  for item in arr {
    guard (item["kind"] as? String) == "transcriber" else {
      throw NSError(
        domain: "speech_kit",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Unsupported module kind (only transcriber)"],
      )
    }
    let localeId = item["locale"] as? String ?? ""
    let presetIdx = item["preset"] as? Int ?? -1
    let locale = Locale(identifier: localeId)
    let preset: SpeechTranscriber.Preset
    switch presetIdx {
    case 0: preset = .transcription
    case 1: preset = .transcriptionWithAlternatives
    case 2: preset = .timeIndexedTranscriptionWithAlternatives
    case 3: preset = .progressiveTranscription
    case 4: preset = .timeIndexedProgressiveTranscription
    default:
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Invalid transcriber preset index"],
      )
    }
    out.append(SpeechTranscriber(locale: locale, preset: preset))
  }
  return out
}

@available(macOS 26.0, *)
private func encodeStatus(_ status: AssetInventory.Status) -> Int32 {
  switch status {
  case .unsupported: return 0
  case .supported: return 1
  case .downloading: return 2
  case .installed: return 3
  default: return 0
  }
}

@available(macOS 26.0, *)
private func runAssetInventoryStatus(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let jsonUtf8 else {
    callback(-1, 2, dupCString("null json pointer"))
    return
  }
  let str = String(cString: jsonUtf8)
  guard let data = str.data(using: .utf8) else {
    callback(-1, 2, dupCString("invalid utf-8"))
    return
  }
  do {
    let modules = try parseModules(data: data)
    let status = await AssetInventory.status(forModules: modules)
    callback(encodeStatus(status), 0, nil)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}

@available(macOS 26.0, *)
private func runAssetEnsureInstalled(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let jsonUtf8 else {
    callback(-1, 2, dupCString("null json pointer"))
    return
  }
  let str = String(cString: jsonUtf8)
  guard let data = str.data(using: .utf8) else {
    callback(-1, 2, dupCString("invalid utf-8"))
    return
  }
  do {
    let modules = try parseModules(data: data)
    if let request = try await AssetInventory.assetInstallationRequest(
      supporting: modules,
    ) {
      try await request.downloadAndInstall()
    }
    callback(0, 0, nil)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}

@_cdecl("sk_asset_inventory_status_async")
public func sk_asset_inventory_status_async(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("AssetInventory requires macOS 26"))
    return
  }
  Task {
    await runAssetInventoryStatus(jsonUtf8: jsonUtf8, callback: callback)
  }
}

@_cdecl("sk_asset_ensure_installed_async")
public func sk_asset_ensure_installed_async(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("AssetInventory requires macOS 26"))
    return
  }
  Task {
    await runAssetEnsureInstalled(jsonUtf8: jsonUtf8, callback: callback)
  }
}

// MARK: - SpeechAnalyzer (file-based) session streaming

private let _analyzerSessionsLock = NSLock()
private var _nextAnalyzerSessionId: Int32 = 1
private var _analyzerSessions: [Int32: Task<Void, Never>] = [:]

@available(macOS 26.0, *)
private func sendAnalyzerResult(
  _ result: SpeechTranscriber.Result,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  let plainText = String(result.text.characters)
  let altTexts = result.alternatives.map { String($0.characters) }

  let rangeStartSeconds = CMTimeGetSeconds(result.range.start)
  let rangeDurationSeconds = CMTimeGetSeconds(result.range.duration)
  let finalizationSeconds = CMTimeGetSeconds(result.resultsFinalizationTime)
  let offsetSeconds = max(0, finalizationSeconds - rangeStartSeconds)

  let payload: [String: Any] = [
    "text": plainText,
    "rangeStartSeconds": rangeStartSeconds,
    "rangeDurationSeconds": rangeDurationSeconds,
    "resultsFinalizationOffsetSeconds": offsetSeconds,
    "alternativeTexts": altTexts,
  ]

  do {
    let data = try JSONSerialization.data(withJSONObject: payload, options: [])
    let jsonStr = String(data: data, encoding: .utf8) ?? "{}"
    callback(0, 0, dupCString(jsonStr))
  } catch {
    // If we fail to serialize a single chunk, keep analysis running.
    // (We intentionally do not end the stream from inside this helper;
    // Dart may close the callback while Swift is still producing results.)
    return
  }
}

@available(macOS 26.0, *)
private func runAnalyzerFileSession(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  audioFilePathUtf8: UnsafePointer<CChar>?,
  sessionId: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let modulesJsonUtf8, let audioFilePathUtf8 else {
    callback(-1, 1, dupCString("Missing modulesJson or audioFilePath"))
    return
  }

  defer {
    _analyzerSessionsLock.lock()
    _analyzerSessions[sessionId] = nil
    _analyzerSessionsLock.unlock()
  }

  let modulesStr = String(cString: modulesJsonUtf8)
  let audioPath = String(cString: audioFilePathUtf8)
  guard let modulesData = modulesStr.data(using: .utf8) else {
    callback(-1, 1, dupCString("Invalid utf-8 modulesJson"))
    return
  }

  var analyzer: SpeechAnalyzer?
  var resultsTask: Task<Void, Error>?
  do {
    let modules = try parseModules(data: modulesData)
    let transcribers = modules.compactMap { $0 as? SpeechTranscriber }
    guard let transcriber = transcribers.first else {
      callback(-1, 2, dupCString("No SpeechTranscriber module found in modules JSON"))
      return
    }

    analyzer = SpeechAnalyzer(modules: modules)
    let audioURL = URL(fileURLWithPath: audioPath)
    let audioFile = try AVAudioFile(forReading: audioURL)

    // Start draining results first so we don't miss early phrases.
    resultsTask = Task<Void, Error> {
      for try await r in transcriber.results {
        if Task.isCancelled { break }
        sendAnalyzerResult(r, callback: callback)
      }
    }

    let lastSampleTime = try await analyzer!.analyzeSequence(from: audioFile)

    if let lastSampleTime {
      try await analyzer!.finalizeAndFinish(through: lastSampleTime)
    } else {
      await analyzer!.cancelAndFinishNow()
    }

    try await resultsTask!.value
    callback(1, 0, nil)
  } catch is CancellationError {
    // Cancellation is an explicit lifecycle operation; treat as clean finish.
    // `cancelAndFinishNow` ensures module result streams terminate.
    if let analyzer {
      await analyzer.cancelAndFinishNow()
    }
    // Best-effort: ensure the results task is stopped.
    if let task = resultsTask {
      _ = try? await task.value
    }
    callback(1, 0, nil)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}

@_cdecl("sk_speech_analyzer_analyze_file_async")
public func sk_speech_analyzer_analyze_file_async(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  audioFilePathUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) -> Int32 {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechAnalyzer requires macOS 26"))
    return -1
  }

  _analyzerSessionsLock.lock()
  let sessionId = _nextAnalyzerSessionId
  _nextAnalyzerSessionId &+= 1
  _analyzerSessionsLock.unlock()

  let task = Task {
    await runAnalyzerFileSession(
      modulesJsonUtf8: modulesJsonUtf8,
      audioFilePathUtf8: audioFilePathUtf8,
      sessionId: sessionId,
      callback: callback,
    )
  }

  _analyzerSessionsLock.lock()
  _analyzerSessions[sessionId] = task
  _analyzerSessionsLock.unlock()

  return sessionId
}

@_cdecl("sk_speech_analyzer_cancel_and_finish_now")
public func sk_speech_analyzer_cancel_and_finish_now(sessionId: Int32) {
  _analyzerSessionsLock.lock()
  let task = _analyzerSessions[sessionId]
  _analyzerSessionsLock.unlock()
  task?.cancel()
}
