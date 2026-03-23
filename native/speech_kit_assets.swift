import Darwin
import Foundation
import CoreMedia
import AVFAudio
import Speech

private func dupCString(_ s: String) -> UnsafeMutablePointer<CChar>? {
  s.withCString { strdup($0) }
}

/// JSON keys: `languageModelPath`, optional `vocabularyPath`, optional `weight` (0.0–1.0).
@available(macOS 26.0, *)
private func speechLanguageModelConfigurationFromPathsDict(
  _ dict: [String: Any],
) throws -> SFSpeechLanguageModel.Configuration {
  let lmPath = dict["languageModelPath"] as? String ?? ""
  guard !lmPath.isEmpty else {
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "languageModelPath must be non-empty"],
    )
  }
  let lmURL = URL(fileURLWithPath: lmPath)
  let vocabStr = dict["vocabularyPath"] as? String
  let weight = dict["weight"] as? Double
  if let w = weight, w < 0 || w > 1 {
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "weight must be between 0.0 and 1.0"],
    )
  }
  if let v = vocabStr, !v.isEmpty {
    let vURL = URL(fileURLWithPath: v)
    if let w = weight {
      return SFSpeechLanguageModel.Configuration(
        languageModel: lmURL,
        vocabulary: vURL,
        weight: NSNumber(value: w),
      )
    }
    return SFSpeechLanguageModel.Configuration(languageModel: lmURL, vocabulary: vURL)
  }
  if let w = weight {
    return SFSpeechLanguageModel.Configuration(
      languageModel: lmURL,
      vocabulary: nil,
      weight: NSNumber(value: w),
    )
  }
  return SFSpeechLanguageModel.Configuration(languageModel: lmURL)
}

@available(macOS 26.0, *)
private func buildSFCustomLanguageModelData(from root: [String: Any]) throws -> SFCustomLanguageModelData {
  let localeId = root["locale"] as? String ?? ""
  let identifier = root["identifier"] as? String ?? ""
  let version = root["version"] as? String ?? ""
  guard !localeId.isEmpty, !identifier.isEmpty, !version.isEmpty else {
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "locale, identifier, and version are required"],
    )
  }
  let locale = Locale(identifier: localeId)
  let model = SFCustomLanguageModelData(locale: locale, identifier: identifier, version: version)
  if let phrases = root["phraseCounts"] as? [[String: Any]] {
    for p in phrases {
      let phrase = p["phrase"] as? String ?? ""
      let count = p["count"] as? Int ?? 0
      if count < 0 {
        throw NSError(
          domain: "speech_kit",
          code: 3,
          userInfo: [NSLocalizedDescriptionKey: "phrase count must be non-negative"],
        )
      }
      model.insert(phraseCount: SFCustomLanguageModelData.PhraseCount(phrase: phrase, count: count))
    }
  }
  if let terms = root["customPronunciations"] as? [[String: Any]] {
    for t in terms {
      let g = t["grapheme"] as? String ?? ""
      let phonemes = t["phonemes"] as? [String] ?? []
      model.insert(
        term: SFCustomLanguageModelData.CustomPronunciation(grapheme: g, phonemes: phonemes),
      )
    }
  }
  if let pctAny = root["phraseCountsFromTemplates"] {
    guard let pctDict = pctAny as? [String: Any] else {
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "phraseCountsFromTemplates must be an object"],
      )
    }
    let classes = try skPhraseCountsClassesFromJson(pctDict["classes"])
    guard let rootNode = pctDict["root"] as? [String: Any] else {
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "phraseCountsFromTemplates.root is required"],
      )
    }
    let classNames = Set(classes.keys)
    let built = try skBuildTemplateInsertable(
      from: rootNode,
      classNames: classNames,
      depth: 0,
    )
    let pct = SFCustomLanguageModelData.PhraseCountsFromTemplates(classes: classes) {
      built
    }
    pct.insert(data: model)
  }
  return model
}

/// Replaces `{className}` with `<className>` for keys in [classNames] (Apple template syntax).
@available(macOS 26.0, *)
private func skNormalizeBracedPlaceholdersForTemplate(
  _ body: String,
  classNames: Set<String>,
) -> String {
  var out = body
  for name in classNames {
    out = out.replacingOccurrences(of: "{\(name)}", with: "<\(name)>")
  }
  return out
}

@available(macOS 26.0, *)
private func skPhraseCountsClassesFromJson(_ any: Any?) throws -> [String: [String]] {
  guard let dict = any as? [String: Any] else {
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "phraseCountsFromTemplates.classes must be an object"],
    )
  }
  var out: [String: [String]] = [:]
  for (key, value) in dict {
    if let arr = value as? [String] {
      out[key] = arr
    } else if let arr = value as? [Any] {
      let strings = arr.compactMap { $0 as? String }
      if strings.count != arr.count {
        throw NSError(
          domain: "speech_kit",
          code: 3,
          userInfo: [
            NSLocalizedDescriptionKey:
              "phraseCountsFromTemplates.classes values must be string arrays",
          ],
        )
      }
      out[key] = strings
    } else {
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [
          NSLocalizedDescriptionKey:
            "phraseCountsFromTemplates.classes values must be string arrays",
        ],
      )
    }
  }
  return out
}

@available(macOS 26.0, *)
private func skBuildTemplateInsertable(
  from dict: [String: Any],
  classNames: Set<String>,
  depth: Int,
) throws -> any TemplateInsertable {
  guard depth <= 32 else {
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "template tree exceeds max depth"],
    )
  }
  let kind = dict["kind"] as? String ?? ""
  switch kind {
  case "template":
    let body = dict["body"] as? String ?? ""
    let count = dict["count"] as? Int ?? 0
    if count < 0 {
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "template count must be non-negative"],
      )
    }
    let normalized = skNormalizeBracedPlaceholdersForTemplate(body, classNames: classNames)
    return SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template(normalized, count: count)
  case "compound":
    let raw = dict["components"] as? [[String: Any]] ?? []
    if raw.isEmpty {
      throw NSError(
        domain: "speech_kit",
        code: 3,
        userInfo: [
          NSLocalizedDescriptionKey: "compound template must have at least one component",
        ],
      )
    }
    var parts: [any TemplateInsertable] = []
    for item in raw {
      parts.append(
        try skBuildTemplateInsertable(
          from: item,
          classNames: classNames,
          depth: depth + 1,
        ),
      )
    }
    return SFCustomLanguageModelData.CompoundTemplate(parts)
  default:
    throw NSError(
      domain: "speech_kit",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "invalid phraseCountsFromTemplates node kind"],
    )
  }
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
      if let lmDict = item["customLanguageModel"] as? [String: Any] {
        let cfg = try speechLanguageModelConfigurationFromPathsDict(lmDict)
        var hints = preset.contentHints
        hints.insert(
          DictationTranscriber.ContentHint.customizedLanguage(modelConfiguration: cfg),
        )
        out.append(
          DictationTranscriber(
            locale: locale,
            contentHints: hints,
            transcriptionOptions: preset.transcriptionOptions,
            reportingOptions: preset.reportingOptions,
            attributeOptions: preset.attributeOptions,
          ),
        )
      } else {
        out.append(DictationTranscriber(locale: locale, preset: preset))
      }

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

/// Maps JSON from Dart (`taskPriority`, `modelRetention`) to `SpeechAnalyzer.Options`.
@available(macOS 26.0, *)
private func speechAnalyzerOptionsFromJsonUtf8(
  _ utf8: UnsafePointer<CChar>?,
) throws -> SpeechAnalyzer.Options? {
  guard let utf8 else { return nil }
  let str = String(cString: utf8)
  if str.isEmpty { return nil }
  guard let data = str.data(using: .utf8) else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid utf-8 analyzer options JSON"],
    )
  }
  guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid analyzer options JSON root"],
    )
  }
  let priorityStr = (root["taskPriority"] as? String) ?? "medium"
  let retentionStr = (root["modelRetention"] as? String) ?? "whileInUse"

  let priority: TaskPriority
  switch priorityStr.lowercased() {
  case "high":
    priority = .high
  case "medium":
    priority = .medium
  case "low":
    priority = .low
  case "background":
    priority = .background
  default:
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid taskPriority: \(priorityStr)"],
    )
  }

  let retention: SpeechAnalyzer.Options.ModelRetention
  switch retentionStr.lowercased() {
  case "whileinuse":
    retention = .whileInUse
  case "lingering":
    retention = .lingering
  case "processlifetime":
    retention = .processLifetime
  default:
    throw NSError(
      domain: "speech_kit",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid modelRetention: \(retentionStr)"],
    )
  }

  return SpeechAnalyzer.Options(priority: priority, modelRetention: retention)
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

/// Maps to `SpeechAnalyzer.prepareToAnalyze(in:withProgressReadyHandler:)` progress events.
@available(macOS 26.0, *)
private func sendPrepareProgressCallback(
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
  fraction: Double,
) {
  let clamped = min(1.0, max(0.0, fraction))
  let payload: [String: Any] = ["fractionCompleted": clamped]
  guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
        let jsonStr = String(data: data, encoding: .utf8)
  else {
    return
  }
  callback(2, 0, dupCString(jsonStr))
}

/// Calls `prepareToAnalyze` with optional `Progress` observation (event type `2` to Dart).
@available(macOS 26.0, *)
private func prepareToAnalyzeForAnalyzer(
  analyzer: SpeechAnalyzer,
  format: AVAudioFormat,
  reportProgress: Bool,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) async throws {
  var progressObservation: NSKeyValueObservation?
  defer {
    progressObservation?.invalidate()
  }
  try await analyzer.prepareToAnalyze(
    in: format,
    withProgressReadyHandler: reportProgress
      ? { progress in
        progressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) { p, _ in
          let frac = p.fractionCompleted
          if frac.isFinite, !frac.isNaN {
            sendPrepareProgressCallback(callback: callback, fraction: frac)
          }
        }
      }
      : nil,
  )
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJson: String?,
  reportPrepareProgress: Bool,
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

    let analyzerOpts = try speechAnalyzerOptionsFromJsonUtf8(analyzerOptionsJsonUtf8)
    if let analyzerOpts {
      analyzer = SpeechAnalyzer(modules: modules, options: analyzerOpts)
    } else {
      analyzer = SpeechAnalyzer(modules: modules)
    }
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }
    let audioURL = URL(fileURLWithPath: audioPath)
    let audioFile = try AVAudioFile(forReading: audioURL)

    let effectivePrepareFormat: AVAudioFormat
    if let prepareFormatJson, !prepareFormatJson.isEmpty {
      effectivePrepareFormat = try avAudioFormatFromCompatibleJsonString(prepareFormatJson)
    } else {
      effectivePrepareFormat = audioFile.processingFormat
    }

    try await prepareToAnalyzeForAnalyzer(
      analyzer: analyzer!,
      format: effectivePrepareFormat,
      reportProgress: reportPrepareProgress,
      callback: callback,
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJson: String?,
  reportPrepareProgress: Bool,
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

    let effectivePrepareFormat: AVAudioFormat
    if let prepareFormatJson, !prepareFormatJson.isEmpty {
      effectivePrepareFormat = try avAudioFormatFromCompatibleJsonString(prepareFormatJson)
    } else {
      effectivePrepareFormat = avFormat
    }

    let analyzerOpts = try speechAnalyzerOptionsFromJsonUtf8(analyzerOptionsJsonUtf8)
    if let analyzerOpts {
      analyzer = SpeechAnalyzer(modules: modules, options: analyzerOpts)
    } else {
      analyzer = SpeechAnalyzer(modules: modules)
    }
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }

    try await prepareToAnalyzeForAnalyzer(
      analyzer: analyzer!,
      format: effectivePrepareFormat,
      reportProgress: reportPrepareProgress,
      callback: callback,
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJson: String?,
  reportPrepareProgress: Bool,
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

    let effectivePrepareFormat: AVAudioFormat
    if let prepareFormatJson, !prepareFormatJson.isEmpty {
      effectivePrepareFormat = try avAudioFormatFromCompatibleJsonString(prepareFormatJson)
    } else {
      effectivePrepareFormat = avFormat
    }

    let analyzerOpts = try speechAnalyzerOptionsFromJsonUtf8(analyzerOptionsJsonUtf8)
    if let analyzerOpts {
      analyzer = SpeechAnalyzer(modules: modules, options: analyzerOpts)
    } else {
      analyzer = SpeechAnalyzer(modules: modules)
    }
    if let ctx = try analysisContextFromJsonUtf8(analysisContextJsonUtf8) {
      try await analyzer!.setContext(ctx)
    }

    try await prepareToAnalyzeForAnalyzer(
      analyzer: analyzer!,
      format: effectivePrepareFormat,
      reportProgress: reportPrepareProgress,
      callback: callback,
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJsonUtf8: UnsafePointer<CChar>?,
  prepareProgressEnabled: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) -> Int32 {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechAnalyzer requires macOS 26"))
    return -1
  }

  let prepareFormatStr: String?
  if let prepareFormatJsonUtf8 {
    let s = String(cString: prepareFormatJsonUtf8)
    prepareFormatStr = s.isEmpty ? nil : s
  } else {
    prepareFormatStr = nil
  }
  let reportPrepareProgress = prepareProgressEnabled != 0

  _analyzerSessionsLock.lock()
  let sessionId = _nextAnalyzerSessionId
  _nextAnalyzerSessionId &+= 1
  _analyzerSessionsLock.unlock()

  let task = Task {
    await runAnalyzerFileSession(
      modulesJsonUtf8: modulesJsonUtf8,
      audioFilePathUtf8: audioFilePathUtf8,
      analysisContextJsonUtf8: analysisContextJsonUtf8,
      analyzerOptionsJsonUtf8: analyzerOptionsJsonUtf8,
      prepareFormatJson: prepareFormatStr,
      reportPrepareProgress: reportPrepareProgress,
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJsonUtf8: UnsafePointer<CChar>?,
  prepareProgressEnabled: Int32,
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

  let prepareFormatStr: String?
  if let prepareFormatJsonUtf8 {
    let s = String(cString: prepareFormatJsonUtf8)
    prepareFormatStr = s.isEmpty ? nil : s
  } else {
    prepareFormatStr = nil
  }
  let reportPrepareProgress = prepareProgressEnabled != 0

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
      analyzerOptionsJsonUtf8: analyzerOptionsJsonUtf8,
      prepareFormatJson: prepareFormatStr,
      reportPrepareProgress: reportPrepareProgress,
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
  analyzerOptionsJsonUtf8: UnsafePointer<CChar>?,
  prepareFormatJsonUtf8: UnsafePointer<CChar>?,
  prepareProgressEnabled: Int32,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) -> Int32 {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechAnalyzer requires macOS 26"))
    return -1
  }

  let prepareFormatStr: String?
  if let prepareFormatJsonUtf8 {
    let s = String(cString: prepareFormatJsonUtf8)
    prepareFormatStr = s.isEmpty ? nil : s
  } else {
    prepareFormatStr = nil
  }
  let reportPrepareProgress = prepareProgressEnabled != 0

  _analyzerSessionsLock.lock()
  let sessionId = _nextAnalyzerSessionId
  _nextAnalyzerSessionId &+= 1
  _analyzerSessionsLock.unlock()

  let task = Task {
    await runAnalyzerPcmStreamSession(
      modulesJsonUtf8: modulesJsonUtf8,
      formatJsonUtf8: formatJsonUtf8,
      analysisContextJsonUtf8: analysisContextJsonUtf8,
      analyzerOptionsJsonUtf8: analyzerOptionsJsonUtf8,
      prepareFormatJson: prepareFormatStr,
      reportPrepareProgress: reportPrepareProgress,
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

@_cdecl("sk_speech_models_end_retention_async")
public func sk_speech_models_end_retention_async(
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SpeechModels requires macOS 26"))
    return
  }
  Task {
    await SpeechModels.endRetention()
    callback(0, 0, nil)
  }
}

@_cdecl("sk_speech_prepare_custom_language_model_async")
public func sk_speech_prepare_custom_language_model_async(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SFSpeechLanguageModel requires macOS 26"))
    return
  }
  guard let jsonUtf8 else {
    callback(-1, 1, dupCString("Missing JSON"))
    return
  }
  let str = String(cString: jsonUtf8)
  guard let data = str.data(using: .utf8),
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else {
    callback(-1, 1, dupCString("Invalid prepareCustomLanguageModel JSON"))
    return
  }
  let assetPath = root["trainingDataAssetPath"] as? String ?? ""
  let outLmPath = root["outputLanguageModelPath"] as? String ?? ""
  guard !assetPath.isEmpty, !outLmPath.isEmpty else {
    callback(
      -1,
      1,
      dupCString("trainingDataAssetPath and outputLanguageModelPath are required"),
    )
    return
  }
  let assetURL = URL(fileURLWithPath: assetPath)
  var lmDict: [String: Any] = ["languageModelPath": outLmPath]
  if let v = root["outputVocabularyPath"] as? String, !v.isEmpty {
    lmDict["vocabularyPath"] = v
  }
  if let w = root["weight"] as? Double {
    lmDict["weight"] = w
  }
  let config: SFSpeechLanguageModel.Configuration
  do {
    config = try speechLanguageModelConfigurationFromPathsDict(lmDict)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
    return
  }
  let ignoresCache = root["ignoresCache"] as? Bool ?? false
  SFSpeechLanguageModel.prepareCustomLanguageModel(
    for: assetURL,
    configuration: config,
    ignoresCache: ignoresCache,
  ) { error in
    if let error {
      callback(-1, 1, dupCString(error.localizedDescription))
    } else {
      callback(0, 0, nil)
    }
  }
}

@_cdecl("sk_speech_export_custom_language_model_data_async")
public func sk_speech_export_custom_language_model_data_async(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("SFCustomLanguageModelData requires macOS 26"))
    return
  }
  guard let jsonUtf8 else {
    callback(-1, 1, dupCString("Missing JSON"))
    return
  }
  let str = String(cString: jsonUtf8)
  guard let data = str.data(using: .utf8),
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else {
    callback(-1, 1, dupCString("Invalid exportCustomLanguageModelData JSON"))
    return
  }
  let exportPath = root["exportPath"] as? String ?? ""
  guard !exportPath.isEmpty else {
    callback(-1, 1, dupCString("exportPath is required"))
    return
  }
  let model: SFCustomLanguageModelData
  do {
    model = try buildSFCustomLanguageModelData(from: root)
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
    return
  }
  let exportURL = URL(fileURLWithPath: exportPath)
  Task {
    do {
      try await model.export(to: exportURL)
      callback(0, 0, nil)
    } catch {
      let ns = error as NSError
      callback(-1, 1, dupCString(ns.localizedDescription))
    }
  }
}

@_cdecl("sk_speech_supported_phonemes_async")
public func sk_speech_supported_phonemes_async(
  jsonUtf8: UnsafePointer<CChar>?,
  callback: @escaping @convention(c) (Int32, Int32, UnsafePointer<CChar>?) -> Void,
) {
  if #unavailable(macOS 26.0) {
    callback(-1, 4, dupCString("supportedPhonemes requires macOS 26"))
    return
  }
  guard let jsonUtf8 else {
    callback(-1, 1, dupCString("Missing JSON"))
    return
  }
  let str = String(cString: jsonUtf8)
  guard let data = str.data(using: .utf8),
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else {
    callback(-1, 1, dupCString("Invalid supportedPhonemes JSON"))
    return
  }
  let localeId = root["locale"] as? String ?? ""
  guard !localeId.isEmpty else {
    callback(-1, 1, dupCString("locale is required"))
    return
  }
  let locale = Locale(identifier: localeId)
  let phonemes = SFCustomLanguageModelData.supportedPhonemes(locale: locale)
  do {
    let out = try JSONSerialization.data(withJSONObject: phonemes, options: [])
    let jsonStr = String(data: out, encoding: .utf8) ?? "[]"
    callback(0, 0, dupCString(jsonStr))
  } catch {
    let ns = error as NSError
    callback(-1, 1, dupCString(ns.localizedDescription))
  }
}
