import UIKit
import SafariServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // MARK: - State
    private var sharedURL: URL?
    private let accentGreen = UIColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 1)

    // MARK: - UI
    private let cardView      = UIView()
    private let iconView      = UIImageView()
    private let titleLabel    = UILabel()
    private let statusLabel   = UILabel()
    private let spinner       = UIActivityIndicatorView(style: .medium)
    private let promptStack   = UIStackView()
    private let submitButton  = UIButton(type: .system)
    private let cancelButton  = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processSharedItems()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let tap = UITapGestureRecognizer(target: self, action: #selector(bgTapped))
        view.addGestureRecognizer(tap)

        cardView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.07, alpha: 1)
        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.6
        cardView.layer.shadowRadius = 24
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.isUserInteractionEnabled = true
        view.addSubview(cardView)

        let bar = UIView()
        bar.backgroundColor = accentGreen
        bar.layer.cornerRadius = 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bar)

        let cfg = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        iconView.image = UIImage(systemName: "clock.arrow.circlepath", withConfiguration: cfg)
        iconView.tintColor = accentGreen
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.text = "Archive2day"
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 20) ?? .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        statusLabel.text = "Checking for archive..."
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(white: 0.5, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 4
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusLabel)

        spinner.color = accentGreen
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(spinner)

        // Prompt stack — shown only when no archive found
        promptStack.axis = .vertical
        promptStack.spacing = 10
        promptStack.isHidden = true
        promptStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(promptStack)

        styleButton(submitButton, title: "Submit for archiving", filled: true)
        submitButton.addTarget(self, action: #selector(submitArchiveTapped), for: .touchUpInside)

        let skipBtn = UIButton(type: .system)
        styleButton(skipBtn, title: "Cancel", filled: false, muted: true)
        skipBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        promptStack.addArrangedSubview(submitButton)
        promptStack.addArrangedSubview(skipBtn)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 14)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 300),

            bar.topAnchor.constraint(equalTo: cardView.topAnchor),
            bar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            bar.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            bar.heightAnchor.constraint(equalToConstant: 3),

            iconView.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            spinner.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            promptStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            promptStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            promptStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            cancelButton.topAnchor.constraint(equalTo: promptStack.bottomAnchor, constant: 4),
            cancelButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
        ])
    }

    private func styleButton(_ btn: UIButton, title: String, filled: Bool, muted: Bool = false) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: filled ? .semibold : .regular)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        if muted {
            btn.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
        } else if filled {
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = accentGreen
        } else {
            btn.setTitleColor(accentGreen, for: .normal)
            btn.backgroundColor = UIColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.12)
            btn.layer.borderColor = UIColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.3).cgColor
            btn.layer.borderWidth = 1
        }
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            showError("No content received"); return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                    DispatchQueue.main.async {
                        if let url = item as? URL { self?.handleURL(url) }
                        else if let str = item as? String, let url = URL(string: str) { self?.handleURL(url) }
                        else { self?.showError("Couldn't read the shared URL") }
                    }
                }
                return
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
                    DispatchQueue.main.async {
                        if let text = item as? String,
                           let url = (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue))?
                               .matches(in: text, range: NSRange(text.startIndex..., in: text)).first?.url {
                            self?.handleURL(url)
                        } else {
                            self?.showError("No URL found in shared text")
                        }
                    }
                }
                return
            }
        }
        showError("Unsupported content type")
    }

    private func handleURL(_ url: URL) {
        sharedURL = url
        let host = url.host ?? url.absoluteString
        updateStatus("Checking archive for\n\(host)...")
        checkArchiveExists(for: url)
    }

    // MARK: - Archive check

    /// Makes a HEAD request to archive.today/newest/{url}.
    /// archive.today returns 200/redirect if an archive exists, 404 if not.
    private func checkArchiveExists(for url: URL) {
        guard let archiveURL = URLCleaner.archiveSearchURL(for: url.absoluteString) else {
            showError("Couldn't build archive URL"); return
        }

        var request = URLRequest(url: archiveURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8

        // Capture the HTTP status — don't follow redirects, just check the response code
        let delegate = StatusCheckDelegate { [weak self] statusCode in
            DispatchQueue.main.async {
                if statusCode == 404 || statusCode == 0 {
                    // No archive found — ask user if they want to submit
                    self?.showNoArchivePrompt()
                } else {
                    // Archive exists — open it directly, no prompt needed
                    self?.openInSafariVC(archiveURL)
                }
            }
        }

        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        session.dataTask(with: request).resume()
    }

    // MARK: - UI state transitions

    private func showNoArchivePrompt() {
        spinner.stopAnimating()
        spinner.isHidden = true
        statusLabel.text = "No archive found for this page.\nWould you like to submit it?"
        statusLabel.textColor = UIColor(white: 0.55, alpha: 1)
        promptStack.isHidden = false
        cancelButton.isHidden = true
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    // MARK: - Actions

    @objc private func submitArchiveTapped() {
        guard let url = sharedURL,
              let submitURL = URLCleaner.archiveSubmitURL(for: url.absoluteString) else {
            cancelTapped(); return
        }
        openInSafariVC(submitURL)
    }

    // MARK: - Open via SFSafariViewController (works from any host app)

    private func openInSafariVC(_ url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cardView.isHidden = true
            self.view.backgroundColor = .clear

            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = self.accentGreen
            safari.delegate = self
            self.present(safari, animated: true)
        }
    }

    // MARK: - Helpers

    private func updateStatus(_ msg: String) {
        DispatchQueue.main.async { self.statusLabel.text = msg }
    }

    private func showError(_ msg: String) {
        DispatchQueue.main.async { [weak self] in
            self?.spinner.stopAnimating()
            self?.statusLabel.text = msg
            self?.statusLabel.textColor = UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1)
        }
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "Archive2day", code: 0))
    }

    @objc private func bgTapped() { cancelTapped() }
}

// MARK: - SFSafariViewControllerDelegate
extension ShareViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - HTTP status delegate (HEAD request, no redirect following)
private class StatusCheckDelegate: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    let completion: (Int) -> Void
    private var handled = false

    init(completion: @escaping (Int) -> Void) {
        self.completion = completion
    }

    // Capture the first response (before any redirect)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard !handled else { completionHandler(.cancel); return }
        handled = true
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        completion(status)
        completionHandler(.cancel)
    }

    // Also catch redirect responses directly
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard !handled else { completionHandler(nil); return }
        handled = true
        // A redirect means an archive exists
        completion(response.statusCode)
        completionHandler(nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !handled else { return }
        handled = true
        completion(0) // Treat network error as "no archive"
    }
}
