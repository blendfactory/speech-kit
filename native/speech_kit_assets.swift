import Darwin
import Foundation
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
