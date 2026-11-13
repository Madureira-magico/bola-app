import UIKit
import WebKit

/// Abre a Bola de Espuma (pasta www, dentro do app) em tela cheia, sem internet.
final class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        // Avisa a página que ela está dentro do app (sem tela preta, sem "Baixar versão nova")
        let flag = WKUserScript(source: "window.__NATIVE_APP__=true;",
                                injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(flag)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsLinkPreview = false
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // a pinça é do efeito, não do zoom da página
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    // Libera o sensor de movimento sem perguntar
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
