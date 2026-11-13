import UIKit
import WebKit
import AVFoundation

/// Abre a Bola de Espuma (pasta www, dentro do app) em tela cheia, sem internet.
final class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    /// A barra de cima (hora, sinal, bateria) é a verdadeira do iPhone; some só durante os vídeos.
    private var esconderBarra = false
    /// O clique da câmera é tocado pelo próprio iPhone (nunca falha).
    private var clique: AVAudioPlayer?

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        // Avisa a página que ela está dentro do app (sem tela preta, sem "Baixar versão nova")
        let flag = WKUserScript(source: "window.__NATIVE_APP__=true;",
                                injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(flag)
        // A página avisa quando abre/fecha os vídeos, para esconder/mostrar a barra
        config.userContentController.add(self, name: "barra")
        // A página pede o clique da câmera (com o volume do menu)
        config.userContentController.add(self, name: "som")

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
        prepararClique()
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // a pinça é do efeito, não do zoom da página
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "som" {
            let volume = (message.body as? NSNumber)?.floatValue ?? 1
            tocarClique(volume: volume)
            return
        }
        guard message.name == "barra", let esconder = message.body as? Bool else { return }
        esconderBarra = esconder
        UIView.animate(withDuration: 0.15) { self.setNeedsStatusBarAppearanceUpdate() }
    }

    private func prepararClique() {
        // .playback: toca mesmo com o iPhone no silencioso; mixWithOthers: não corta outros sons
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: "clique", withExtension: "mp3") {
            clique = try? AVAudioPlayer(contentsOf: url)
            clique?.prepareToPlay()
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            try? AVAudioSession.sharedInstance().setActive(true)
            self?.clique?.prepareToPlay()
        }
    }

    private func tocarClique(volume: Float) {
        guard let p = clique, volume > 0 else { return }
        p.volume = min(1, max(0, volume))
        if p.isPlaying { p.stop() }
        p.currentTime = 0
        if !p.play() {
            try? AVAudioSession.sharedInstance().setActive(true)
            p.prepareToPlay()
            p.play()
        }
    }

    // Libera o sensor de movimento sem perguntar
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    override var prefersStatusBarHidden: Bool { esconderBarra }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
