import Foundation

final class BonjourKick: NSObject, NetServiceBrowserDelegate {
    private let browser = NetServiceBrowser()

    func start() {
        browser.delegate = self
        browser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        // no-op
    }
}