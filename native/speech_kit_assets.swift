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
    let kind = item["kind"] as? String ?? ""
    let localeId = item["locale"] as? String ?? ""
    let presetIdx = item["preset"] as? Int ?? -1
    let locale = Locale(identifier: localeId)

    switch kind {
    case "transcriber":
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
          userInfo: [NSLocalizedDescriptionKey: "Invalid SpeechTranscriber preset index"],
        )
      }
      out.append(SpeechTranscriber(locale: locale, preset: preset))

    case "dictation":
      let preset: DictationTranscriber.Preset
      switch presetIdx {
      case 0: preset = .phrase
      case 1: preset = .shortDictation
      case 2: preset = .progressiveShortDictation
      case 3: preset = .longDictation
      case 4: preset = .progressiveLongDictation
      case 5: preset = .timeIndexedLongDictation
      default:
        throw NSError(
          domain: "speech_kit",
          code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Invalid DictationTranscriber preset index"],
        )
      }
      out.append(DictationTranscriber(locale: locale, preset: preset))

    case "speechDetector":
      let sensIdx = item["sensitivity"] as? Int ?? 1
      let sensitivity: SpeechDetector.SensitivityLevel
      switch sensIdx {
      case 0: sensitivity = .low
      case 1: sensitivity = .medium
      case 2: sensitivity = .high
      default:
        throw NSError(
          domain: "speech_kit",
          code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Invalid SpeechDetector sensitivity index"],
        )
      }
      let reportResults = item["reportResults"] as? Bool ?? false
      out.append(
        SpeechDetector(
          detectionOptions: SpeechDetector.DetectionOptions(sensitivityLevel: sensitivity),
          reportResults: reportResults,
        ),
      )

    default:
      throw NSError(
        domain: "speech_kit",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Unsupported module kind"],
      )
    }
  }
  return out
}

@available(macOS 26.0, *)
private func analysisContextFromJsonUtf8(
  _ utf8: UnsafePointer<CChar>?,
) throws -> AnalysisContext? {
  guard let utf8 else { return nil }
  let str = String(cString: utf8)
  guard let data = str.data(using: .utf8) else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid utf-8 analysis context JSON"],
    )
  }
  guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid analysis context JSON root"],
    )
  }
  guard let contextual = root["contextualStrings"] as? [String: Any],
        !contextual.isEmpty
  else {
    return nil
  }
  let ctx = AnalysisContext()
  for (tagStr, valueAny) in contextual {
    guard let arr = valueAny as? [String] else { continue }
    let tag: AnalysisContext.ContextualStringsTag
    if tagStr == "general" {
      tag = .general
    } else {
      tag = AnalysisContext.ContextualStringsTag(tagStr)
    }
    ctx.contextualStrings[tag] = arr
  }
  return ctx
}

@available(macOS 26.0, *)
private func avAudioFormatFromCompatibleJsonString(_ str: String) throws -> AVAudioFormat {
  guard let data = str.data(using: .utf8) else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid format utf-8"],
    )
  }
  guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid format JSON"],
    )
  }
  let sampleRate = obj["sampleRate"] as? Double ?? 0
  let channelCount = obj["channelCount"] as? Int ?? 0
  let cfRaw = UInt(obj["commonFormat"] as? Int ?? 0)
  let interleaved = obj["isInterleaved"] as? Bool ?? true
  guard sampleRate > 0, channelCount > 0 else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid sampleRate or channelCount"],
    )
  }
  let common = AVAudioCommonFormat(rawValue: cfRaw) ?? .pcmFormatFloat32
  guard let fmt = AVAudioFormat(
    commonFormat: common,
    sampleRate: sampleRate,
    channels: AVAudioChannelCount(channelCount),
    interleaved: interleaved
  ) else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Could not build AVAudioFormat"],
    )
  }
  return fmt
}

@available(macOS 26.0, *)
private func avAudioPCMBuffer(pcmData: Data, format: AVAudioFormat) throws -> AVAudioPCMBuffer {
  let bpf = Int(format.streamDescription.pointee.mBytesPerFrame)
  guard bpf > 0 else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid bytes-per-frame in format"],
    )
  }
  guard !pcmData.isEmpty else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Empty PCM data"],
    )
  }
  guard pcmData.count % bpf == 0 else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "PCM length is not a multiple of frame size"],
    )
  }
  let frameCount = pcmData.count / bpf
  guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Could not allocate AVAudioPCMBuffer"],
    )
  }
  buffer.frameLength = AVAudioFrameCount(frameCount)
  guard let dst = buffer.mutableAudioBufferList.pointee.mBuffers.mData else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "No buffer storage"],
    )
  }
  pcmData.withUnsafeBytes { raw in
    guard let src = raw.baseAddress else { return }
    memcpy(dst, src, pcmData.count)
  }
  return buffer
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

// MARK: - SpeechAnalyzer.bestAvailableAudioFormat

@available(macOS 26.0, *)
private func runBestAvailableAudioFormat(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let modulesJsonUtf8 else {
    callback(-1, 2, dupCString("null json pointer"))
    return
  }
  let str = String(cString: modulesJsonUtf8)
  guard let data = str.data(using: .utf8) else {
    callback(-1, 2, dupCString("invalid utf-8"))
    return
  }
  do {
    let modules = try parseModules(data: data)
    let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules)
    guard let format else {
      callback(
        -1,
        5,
        dupCString(
          "bestAvailableAudioFormat returned nil; install on-device assets first."
        ),
      )
      return
    }
    let payload: [String: Any] = [
      "sampleRate": format.sampleRate,
      "channelCount": Int(format.channelCount),
      "commonFormat": Int(format.commonFormat.rawValue),
      "isInterleaved": format.isInterleaved,
    ]
    let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
    let jsonStr = String(data: jsonData, encoding: .utf8) ?? "{}"
    callback(0, 0, dupCString(jsonStr))
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}

@_cdecl("sk_speech_best_available_audio_format_async")
public func sk_speech_best_available_audio_format_async(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechAnalyzer requires macOS 26"))
    return
  }
  Task {
    await runBestAvailableAudioFormat(modulesJsonUtf8: modulesJsonUtf8, callback: callback)
  }
}

// MARK: - SpeechAnalyzer (file-based) session streaming

private let _analyzerSessionsLock = NSLock()
// Swift 6: `MutableGlobalVariable` — opt out explicitly; all reads/writes are
// serialized by `_analyzerSessionsLock` in the C entry points and
// `_unregisterAnalyzerSession`.
nonisolated(unsafe) private var _nextAnalyzerSessionId: Int32 = 1
nonisolated(unsafe) private var _analyzerSessions: [Int32: Task<Void, Never>] = [:]

/// Removes a session entry from the global map. Must use `NSLock` only from
/// synchronous call sites so Swift 6 does not treat `lock()` as crossing an
/// async isolation boundary (see `runAnalyzerFileSession` `defer`).
private func _unregisterAnalyzerSession(_ sessionId: Int32) {
  _analyzerSessionsLock.lock()
  defer { _analyzerSessionsLock.unlock() }
  _analyzerSessions[sessionId] = nil
}

// MARK: - PCM stream bridge (multi-chunk AnalyzerInput)

private let _pcmStreamLock = NSLock()
nonisolated(unsafe) private var _pcmStreamBridges: [Int32: PcmStreamBridge] = [:]

@available(macOS 26.0, *)
private final class PcmStreamBridge: @unchecked Sendable {
  let format: AVAudioFormat
  private let lock = NSLock()
  private var continuation: AsyncStream<AnalyzerInput>.Continuation?

  init(format: AVAudioFormat, continuation: AsyncStream<AnalyzerInput>.Continuation) {
    self.format = format
    self.continuation = continuation
  }

  func pushPCM(_ data: Data) throws {
    lock.lock()
    defer { lock.unlock() }
    guard let cont = continuation else {
      throw NSError(
        domain: "speech_kit",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "PCM stream already finished"],
      )
    }
    if data.isEmpty {
      return
    }
    let buf = try avAudioPCMBuffer(pcmData: data, format: format)
    cont.yield(AnalyzerInput(buffer: buf))
  }

  func finishInput() {
    lock.lock()
    defer { lock.unlock() }
    continuation?.finish()
    continuation = nil
  }
}

@available(macOS 26.0, *)
private func _registerPcmStream(sessionId: Int32, bridge: PcmStreamBridge) {
  _pcmStreamLock.lock()
  defer { _pcmStreamLock.unlock() }
  _pcmStreamBridges[sessionId] = bridge
}

@available(macOS 26.0, *)
private func _unregisterPcmStreamIfPresent(_ sessionId: Int32) {
  _pcmStreamLock.lock()
  defer { _pcmStreamLock.unlock() }
  if let bridge = _pcmStreamBridges.removeValue(forKey: sessionId) {
    bridge.finishInput()
  }
}

@available(macOS 26.0, *)
private func _pcmStreamBridge(for sessionId: Int32) -> PcmStreamBridge? {
  _pcmStreamLock.lock()
  defer { _pcmStreamLock.unlock() }
  return _pcmStreamBridges[sessionId]
}

@available(macOS 26.0, *)
private func sendSpeechTranscriberAnalyzerResult(
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
private func sendDictationTranscriberAnalyzerResult(
  _ result: DictationTranscriber.Result,
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
    return
  }
}

@available(macOS 26.0, *)
private func runAnalyzerFileSession(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  audioFilePathUtf8: UnsafePointer<CChar>?,
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
  sessionId: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let modulesJsonUtf8, let audioFilePathUtf8 else {
    callback(-1, 1, dupCString("Missing modulesJson or audioFilePath"))
    return
  }

  defer {
    _unregisterAnalyzerSession(sessionId)
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

    var speechTranscriber: SpeechTranscriber?
    var dictationTranscriber: DictationTranscriber?
    for m in modules {
      if let s = m as? SpeechTranscriber {
        speechTranscriber = s
        break
      }
      if let d = m as? DictationTranscriber {
        dictationTranscriber = d
        break
      }
    }
    guard speechTranscriber != nil || dictationTranscriber != nil else {
      callback(
        -1,
        2,
        dupCString("No SpeechTranscriber or DictationTranscriber module in modules JSON"),
      )
      return
    }

    analyzer = SpeechAnalyzer(modules: modules)
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }
    let audioURL = URL(fileURLWithPath: audioPath)
    let audioFile = try AVAudioFile(forReading: audioURL)

    try await analyzer!.prepareToAnalyze(
      in: audioFile.processingFormat,
      withProgressReadyHandler: nil,
    )

    // Start draining results first so we don't miss early phrases.
    if let transcriber = speechTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendSpeechTranscriberAnalyzerResult(r, callback: callback)
        }
      }
    } else if let transcriber = dictationTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendDictationTranscriberAnalyzerResult(r, callback: callback)
        }
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

@available(macOS 26.0, *)
private func runAnalyzerPcmSession(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  formatJsonUtf8: UnsafePointer<CChar>?,
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
  pcmData: Data,
  sessionId: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let modulesJsonUtf8, let formatJsonUtf8 else {
    callback(-1, 1, dupCString("Missing modulesJson or formatJson"))
    return
  }

  defer {
    _unregisterAnalyzerSession(sessionId)
  }

  let modulesStr = String(cString: modulesJsonUtf8)
  let formatStr = String(cString: formatJsonUtf8)
  guard let modulesData = modulesStr.data(using: .utf8) else {
    callback(-1, 1, dupCString("Invalid utf-8 modulesJson"))
    return
  }

  var analyzer: SpeechAnalyzer?
  var resultsTask: Task<Void, Error>?
  do {
    let modules = try parseModules(data: modulesData)

    var speechTranscriber: SpeechTranscriber?
    var dictationTranscriber: DictationTranscriber?
    for m in modules {
      if let s = m as? SpeechTranscriber {
        speechTranscriber = s
        break
      }
      if let d = m as? DictationTranscriber {
        dictationTranscriber = d
        break
      }
    }
    guard speechTranscriber != nil || dictationTranscriber != nil else {
      callback(
        -1,
        2,
        dupCString("No SpeechTranscriber or DictationTranscriber module in modules JSON"),
      )
      return
    }

    let avFormat = try avAudioFormatFromCompatibleJsonString(formatStr)

    analyzer = SpeechAnalyzer(modules: modules)
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }

    try await analyzer!.prepareToAnalyze(
      in: avFormat,
      withProgressReadyHandler: nil,
    )

    if let transcriber = speechTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendSpeechTranscriberAnalyzerResult(r, callback: callback)
        }
      }
    } else if let transcriber = dictationTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendDictationTranscriberAnalyzerResult(r, callback: callback)
        }
      }
    }

    let pcmBuffer = try avAudioPCMBuffer(pcmData: pcmData, format: avFormat)
    let inputStream = AsyncStream<AnalyzerInput> { continuation in
      continuation.yield(AnalyzerInput(buffer: pcmBuffer))
      continuation.finish()
    }

    let lastSampleTime = try await analyzer!.analyzeSequence(inputStream)

    if let lastSampleTime {
      try await analyzer!.finalizeAndFinish(through: lastSampleTime)
    } else {
      await analyzer!.cancelAndFinishNow()
    }

    try await resultsTask!.value
    callback(1, 0, nil)
  } catch is CancellationError {
    if let analyzer {
      await analyzer.cancelAndFinishNow()
    }
    if let task = resultsTask {
      _ = try? await task.value
    }
    callback(1, 0, nil)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}

@available(macOS 26.0, *)
private func runAnalyzerPcmStreamSession(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  formatJsonUtf8: UnsafePointer<CChar>?,
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
  sessionId: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async {
  guard let modulesJsonUtf8, let formatJsonUtf8 else {
    callback(-1, 1, dupCString("Missing modulesJson or formatJson"))
    return
  }

  defer {
    _unregisterPcmStreamIfPresent(sessionId)
    _unregisterAnalyzerSession(sessionId)
  }

  let modulesStr = String(cString: modulesJsonUtf8)
  let formatStr = String(cString: formatJsonUtf8)
  guard let modulesData = modulesStr.data(using: .utf8) else {
    callback(-1, 1, dupCString("Invalid utf-8 modulesJson"))
    return
  }

  var analyzer: SpeechAnalyzer?
  var resultsTask: Task<Void, Error>?
  do {
    let modules = try parseModules(data: modulesData)

    var speechTranscriber: SpeechTranscriber?
    var dictationTranscriber: DictationTranscriber?
    for m in modules {
      if let s = m as? SpeechTranscriber {
        speechTranscriber = s
        break
      }
      if let d = m as? DictationTranscriber {
        dictationTranscriber = d
        break
      }
    }
    guard speechTranscriber != nil || dictationTranscriber != nil else {
      callback(
        -1,
        2,
        dupCString("No SpeechTranscriber or DictationTranscriber module in modules JSON"),
      )
      return
    }

    let avFormat = try avAudioFormatFromCompatibleJsonString(formatStr)

    analyzer = SpeechAnalyzer(modules: modules)
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }

    try await analyzer!.prepareToAnalyze(
      in: avFormat,
      withProgressReadyHandler: nil,
    )

    let (inputStream, streamContinuation) = AsyncStream<AnalyzerInput>.makeStream(
      of: AnalyzerInput.self,
    )
    let bridge = PcmStreamBridge(format: avFormat, continuation: streamContinuation)
    _registerPcmStream(sessionId: sessionId, bridge: bridge)

    if let transcriber = speechTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendSpeechTranscriberAnalyzerResult(r, callback: callback)
        }
      }
    } else if let transcriber = dictationTranscriber {
      resultsTask = Task<Void, Error> {
        for try await r in transcriber.results {
          if Task.isCancelled { break }
          sendDictationTranscriberAnalyzerResult(r, callback: callback)
        }
      }
    }

    let lastSampleTime = try await analyzer!.analyzeSequence(inputStream)

    if let lastSampleTime {
      try await analyzer!.finalizeAndFinish(through: lastSampleTime)
    } else {
      await analyzer!.cancelAndFinishNow()
    }

    try await resultsTask!.value
    callback(1, 0, nil)
  } catch is CancellationError {
    if let analyzer {
      await analyzer.cancelAndFinishNow()
    }
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
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
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
      analysisContextJsonUtf8: analysisContextJsonUtf8,
      sessionId: sessionId,
      callback: callback,
    )
  }

  _analyzerSessionsLock.lock()
  _analyzerSessions[sessionId] = task
  _analyzerSessionsLock.unlock()

  return sessionId
}

@_cdecl("sk_speech_analyzer_analyze_pcm_async")
public func sk_speech_analyzer_analyze_pcm_async(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  formatJsonUtf8: UnsafePointer<CChar>?,
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
  pcmBytes: UnsafePointer<UInt8>?,
  pcmByteLength: Int64,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) -> Int32 {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechAnalyzer requires macOS 26"))
    return -1
  }

  let pcmData: Data
  if pcmByteLength > 0, let pcmBytes {
    pcmData = Data(bytes: pcmBytes, count: Int(pcmByteLength))
  } else {
    pcmData = Data()
  }

  _analyzerSessionsLock.lock()
  let sessionId = _nextAnalyzerSessionId
  _nextAnalyzerSessionId &+= 1
  _analyzerSessionsLock.unlock()

  let task = Task {
    await runAnalyzerPcmSession(
      modulesJsonUtf8: modulesJsonUtf8,
      formatJsonUtf8: formatJsonUtf8,
      analysisContextJsonUtf8: analysisContextJsonUtf8,
      pcmData: pcmData,
      sessionId: sessionId,
      callback: callback,
    )
  }

  _analyzerSessionsLock.lock()
  _analyzerSessions[sessionId] = task
  _analyzerSessionsLock.unlock()

  return sessionId
}

@_cdecl("sk_speech_analyzer_start_pcm_stream_async")
public func sk_speech_analyzer_start_pcm_stream_async(
  modulesJsonUtf8: UnsafePointer<CChar>?,
  formatJsonUtf8: UnsafePointer<CChar>?,
  analysisContextJsonUtf8: UnsafePointer<CChar>?,
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
    await runAnalyzerPcmStreamSession(
      modulesJsonUtf8: modulesJsonUtf8,
      formatJsonUtf8: formatJsonUtf8,
      analysisContextJsonUtf8: analysisContextJsonUtf8,
      sessionId: sessionId,
      callback: callback,
    )
  }

  _analyzerSessionsLock.lock()
  _analyzerSessions[sessionId] = task
  _analyzerSessionsLock.unlock()

  return sessionId
}

@_cdecl("sk_speech_analyzer_push_pcm_chunk")
public func sk_speech_analyzer_push_pcm_chunk(
  sessionId: Int32,
  pcmBytes: UnsafePointer<UInt8>?,
  pcmByteLength: Int64,
) -> Int32 {
  if #unavailable(macOS 26.0) {
    return -1
  }
  if pcmByteLength <= 0 {
    return 0
  }
  guard let pcmBytes else {
    return -2
  }
  let data = Data(bytes: pcmBytes, count: Int(pcmByteLength))
  guard let bridge = _pcmStreamBridge(for: sessionId) else {
    return -1
  }
  do {
    try bridge.pushPCM(data)
    return 0
  } catch {
    return -2
  }
}

@_cdecl("sk_speech_analyzer_finish_pcm_input")
public func sk_speech_analyzer_finish_pcm_input(sessionId: Int32) {
  if #unavailable(macOS 26.0) {
    return
  }
  _pcmStreamLock.lock()
  defer { _pcmStreamLock.unlock() }
  if let bridge = _pcmStreamBridges.removeValue(forKey: sessionId) {
    bridge.finishInput()
  }
}

@_cdecl("sk_speech_analyzer_cancel_and_finish_now")
public func sk_speech_analyzer_cancel_and_finish_now(sessionId: Int32) {
  _analyzerSessionsLock.lock()
  let task = _analyzerSessions[sessionId]
  _analyzerSessionsLock.unlock()
  task?.cancel()
}
