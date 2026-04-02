import AppKit

if CommandLine.arguments.count < 2 {
    if let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http://example.com")!) {
        if let bundle = Bundle(url: url)?.bundleIdentifier {
            print(bundle)
        }
    }
} else {
    let bid = CommandLine.arguments[1]
    guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) else {
        fputs("app no encontrada: \(bid)\n", stderr)
        exit(1)
    }

    let schemes = ["http", "https"]
    let group = DispatchGroup()
    var failed = false

    for scheme in schemes {
        group.enter()
        NSWorkspace.shared.setDefaultApplication(at: appUrl, toOpenURLsWithScheme: scheme) { error in
            if let error = error {
                fputs("\(scheme): \(error.localizedDescription)\n", stderr)
                failed = true
            }
            group.leave()
        }
    }

    group.wait()
    exit(failed ? 1 : 0)
}
