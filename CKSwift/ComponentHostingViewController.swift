// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

import UIKit

final class ObjCProviderWrapper: NSObject {
  let provider: () -> Component

  init(provider: @escaping () -> Component) {
    self.provider = provider
  }
}

public final class ComponentHostingViewController: UIViewController {
  private let rootComponentProvider: () -> Component
  private let hostingView: ComponentHostingView<NSObject, ObjCProviderWrapper>

  #if swift(>=5.3)

  public init(@ComponentBuilder rootComponentProvider: @escaping () -> Component) {
    self.rootComponentProvider = rootComponentProvider
    hostingView = ComponentHostingView(componentProvider: { _, wrapper in wrapper!.provider() },
                                       sizeRangeProviderBlock: { size in SizeRange(minSize: .zero, maxSize: size) })
    super.init(nibName: nil, bundle: nil)
  }

  #else

  public init(rootComponentProvider: @escaping () -> Component) {
    self.rootComponentProvider = rootComponentProvider
    hostingView = ComponentHostingView(componentProvider: { _, wrapper in wrapper!.provider() },
                                       sizeRangeProviderBlock: { size in SizeRange(minSize: .zero, maxSize: size) })
    super.init(nibName: nil, bundle: nil)
  }

  #endif

  required init(coder: NSCoder) {
    fatalError()
  }

  public override func viewDidLoad() {
    view.backgroundColor = .white

    hostingView.updateContext(ObjCProviderWrapper(provider: rootComponentProvider), mode: .synchronous)

    view.addSubview(hostingView)
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    hostingView.hostingViewWillAppear()
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    hostingView.hostingViewDidDisappear()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let constrainingSize = CGSize(width: view.bounds.width,
                                  height: view.bounds.height - topLayoutGuide.length)
    let hostingViewSize = hostingView.sizeThatFits(constrainingSize)
    let hostingViewFrame = CGRect(origin: CGPoint(x: 0, y: topLayoutGuide.length),
                                  size: hostingViewSize)
    hostingView.frame = hostingViewFrame
  }
}

extension ComponentHostingViewController: ComponentHostingViewDelegate {
  public func componentHostingViewDidInvalidateSize(_: UIView) {
    view.setNeedsLayout()
  }
}
