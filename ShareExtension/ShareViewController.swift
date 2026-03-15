import UIKit
import SafariServices
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "com.yourname.archive2day.ShareExtension", category: "ShareViewController")

class ShareViewController: UIViewController {

    private let accentGreen = UIColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 1)
    private let cardView    = UIView()
    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let statusLabel = UILabel()
    private let spinner     = UIActivityIndicatorView(style: .medium)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processSharedItems()
    }

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

        statusLabel.text = "Opening archive..."
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(white: 0.5, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 3
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusLabel)

        spinner.color = accentGreen
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(spinner)

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

            cancelButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            logger.error("No extension input items received")
            showError("No content received")
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                    if let error = error { logger.error("Failed to load URL: \(error.localizedDescription)") }
                    DispatchQueue.main.async {
                        if let url = item as? URL { self?.handleURL(url) }
                        else if let str = item as? String, let url = URL(string: str) { self?.handleURL(url) }
                        else { self?.showError("Couldn't read the shared URL") }
                    }
                }
                return
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                    if let error = error { logger.error("Failed to load text: \(error.localizedDescription)") }
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
        switch URLCleaner.validate(url.absoluteString) {
        case .failure(let error):
            logger.warning("URL validation failed: \(error.localizedDescription)")
            showError(error.errorDescription ?? "Invalid URL")
            return
        case .success:
            break
        }

        logger.info("Opening archive for: \(url.absoluteString)")

        guard let archiveURL = URLCleaner.archiveSearchURL(for: url.absoluteString) else {
            showError("Couldn't build archive URL")
            return
        }

        // Go straight to archive.today/newest/{url} — no pre-check.
        // If no archive exists, archive.today shows its own page where the user can submit.
        openInSafariVC(archiveURL)
    }

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

extension ShareViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
