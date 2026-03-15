import Foundation

/// All external service URLs and archive.today logic in one place.
/// If archive.today changes its URL structure, update here only.
enum ExternalURLs {
    static let archiveNewest = "https://archive.today/newest/"
    static let archiveSubmit = "https://archive.today/?run=1&url="
}

/// Result of checking whether an archive exists
enum ArchiveCheckResult {
    case exists         // 200 or redirect — archive found, open it
    case notFound       // 404 — never archived, offer to submit
    case error(String)  // 5xx, timeout, network failure — don't assume either way
}

/// Validation errors for URL checking
enum URLValidationError: LocalizedError {
    case empty
    case malformed
    case invalidScheme
    case missingHost

    var errorDescription: String? {
        switch self {
        case .empty:         return "URL is empty"
        case .malformed:     return "Not a valid URL"
        case .invalidScheme: return "URL must start with http:// or https://"
        case .missingHost:   return "URL has no host"
        }
    }
}

/// Cleans and prepares URLs for archive.today lookup
enum URLCleaner {

    private static let trackingParams: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "utm_id", "fbclid", "gclid", "msclkid", "mc_eid", "ref", "referrer",
        "_hsenc", "_hsmi", "hsCtaTracking", "mkt_tok", "igshid", "s_cid",
        "ncid", "cid", "wt.mc_id", "wt.srch", "ocid", "feature", "src"
    ]

    /// Validates that a URL string is well-formed with an https/http scheme and a host
    static func validate(_ urlString: String) -> Result<URL, URLValidationError> {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }
        guard let url = URL(string: trimmed) else { return .failure(.malformed) }
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            return .failure(.invalidScheme)
        }
        guard let host = url.host, !host.isEmpty else { return .failure(.missingHost) }
        return .success(url)
    }

    /// Strips tracking parameters and fragment from a URL
    static func clean(_ urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        if let items = components.queryItems {
            let filtered = items.filter { !trackingParams.contains($0.name.lowercased()) }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }
        components.fragment = nil
        return components.url?.absoluteString ?? urlString
    }

    /// Builds the archive.today URL to view the newest snapshot
    static func archiveSearchURL(for url: String) -> URL? {
        let cleaned = clean(url)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        return URL(string: "\(ExternalURLs.archiveNewest)\(encoded)")
    }

    /// Builds the archive.today URL to submit a new snapshot
    static func archiveSubmitURL(for url: String) -> URL? {
        let cleaned = clean(url)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        return URL(string: "\(ExternalURLs.archiveSubmit)\(encoded)")
    }
}
