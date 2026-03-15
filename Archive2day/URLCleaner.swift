import Foundation

/// Cleans and prepares URLs for archive.today lookup
enum URLCleaner {

    /// Strips tracking parameters, fragments, and normalizes the URL
    /// so archive.today gets a clean canonical URL to look up
    static func clean(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return trimmed }

        // Remove tracking/UTM query params that pollute the archive lookup
        let trackingParams: Set<String> = [
            "utm_source","utm_medium","utm_campaign","utm_term","utm_content",
            "utm_id","fbclid","gclid","msclkid","mc_eid","ref","referrer",
            "_hsenc","_hsmi","hsCtaTracking","mkt_tok","igshid","s_cid",
            "ncid","cid","WT.mc_id","WT.srch","ocid","feature","src"
        ]

        if let items = components.queryItems {
            let filtered = items.filter { !trackingParams.contains($0.name.lowercased()) && !trackingParams.contains($0.name) }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }

        // Remove fragment (archive.today ignores it anyway)
        components.fragment = nil

        return components.url?.absoluteString ?? trimmed
    }

    /// Builds the archive.today URL to check for an existing snapshot
    static func archiveSearchURL(for url: String) -> URL? {
        let cleaned = clean(url)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        return URL(string: "https://archive.today/newest/\(encoded)")
    }

    /// Builds the archive.today URL to submit a new snapshot
    static func archiveSubmitURL(for url: String) -> URL? {
        let cleaned = clean(url)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        return URL(string: "https://archive.today/?run=1&url=\(encoded)")
    }
}
