// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import QRCodeReaderViewController

protocol TransferTokensCardViaWalletAddressViewControllerDelegate: class, CanOpenURL {
    func didEnterWalletAddress(tokenHolder: TokenHolder, to walletAddress: String, paymentFlow: PaymentFlow, in viewController: TransferTokensCardViaWalletAddressViewController)
    func didPressViewInfo(in viewController: TransferTokensCardViaWalletAddressViewController)
}

class TransferTokensCardViaWalletAddressViewController: UIViewController, TokenVerifiableStatusViewController, CanScanQRCode {
    private let token: TokenObject
    private let roundedBackground = RoundedBackground()
    private let header = TokensCardViewControllerTitleHeader()
    private let tokenRowView: TokenRowView & UIView
    private let targetAddressTextField = AddressTextField()
    private let nextButton = UIButton(type: .system)
    private var viewModel: TransferTokensCardViaWalletAddressViewControllerViewModel
    private var tokenHolder: TokenHolder
    private var paymentFlow: PaymentFlow

    let config: Config
    var contract: String {
        return token.contract
    }
    weak var delegate: TransferTokensCardViaWalletAddressViewControllerDelegate?

    init(
            config: Config,
            token: TokenObject,
            tokenHolder: TokenHolder,
            paymentFlow: PaymentFlow,
            viewModel: TransferTokensCardViaWalletAddressViewControllerViewModel
    ) {
        self.config = config
        self.token = token
        self.tokenHolder = tokenHolder
        self.paymentFlow = paymentFlow
        self.viewModel = viewModel

        let tokenType = OpenSeaNonFungibleTokenHandling(token: token)
        switch tokenType {
        case .supportedByOpenSea:
            tokenRowView = OpenSeaNonFungibleTokenCardRowView()
        case .notSupportedByOpenSea:
            tokenRowView = TokenCardRowView()
        }

        super.init(nibName: nil, bundle: nil)

        updateNavigationRightBarButtons(isVerified: true)

        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        targetAddressTextField.ensAddressLabel.translatesAutoresizingMaskIntoConstraints = false

        targetAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        targetAddressTextField.delegate = self
        targetAddressTextField.returnKeyType = .done

        nextButton.setTitle(R.string.localizable.aWalletNextButtonTitle(), for: .normal)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        tokenRowView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tokenRowView)

        let stackView = [
            header,
            tokenRowView,
            .spacer(height: 10),
            targetAddressTextField.ensAddressLabel,
            .spacer(height: ScreenChecker().isNarrowScreen() ? 2 : 4),
            targetAddressTextField,
        ].asStackView(axis: .vertical, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackground.addSubview(stackView)

        let buttonsStackView = [nextButton].asStackView(distribution: .fillEqually, contentHuggingPriority: .required)
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        let footerBar = UIView()
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        footerBar.backgroundColor = Colors.appHighlightGreen
        roundedBackground.addSubview(footerBar)

        let buttonsHeight = Metrics.greenButtonHeight
        footerBar.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
			header.heightAnchor.constraint(equalToConstant: 90),

            tokenRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tokenRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            targetAddressTextField.leadingAnchor.constraint(equalTo: roundedBackground.leadingAnchor, constant: 30),
            targetAddressTextField.trailingAnchor.constraint(equalTo: roundedBackground.trailingAnchor, constant: -30),

            stackView.leadingAnchor.constraint(equalTo: roundedBackground.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: roundedBackground.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: roundedBackground.topAnchor),

            buttonsStackView.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: footerBar.topAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: buttonsHeight),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.topAnchor.constraint(equalTo: view.layoutGuide.bottomAnchor, constant: -buttonsHeight),
            footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ] + roundedBackground.createConstraintsWithContainer(view: view))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func nextButtonTapped() {
        let address = targetAddressTextField.value.trimmed
        delegate?.didEnterWalletAddress(tokenHolder: tokenHolder, to: address, paymentFlow: paymentFlow, in: self)
    }

    func showInfo() {
        delegate?.didPressViewInfo(in: self)
    }

    func showContractWebPage() {
        delegate?.didPressViewContractWebPage(forContract: contract, in: self)
    }

    func configure(viewModel newViewModel: TransferTokensCardViaWalletAddressViewControllerViewModel? = nil) {
        if let newViewModel = newViewModel {
            viewModel = newViewModel
        }
        updateNavigationRightBarButtons(isVerified: isContractVerified)

        view.backgroundColor = viewModel.backgroundColor

        header.configure(title: viewModel.headerTitle)

        tokenRowView.configure(tokenHolder: tokenHolder)

        tokenRowView.stateLabel.isHidden = true

        targetAddressTextField.ensAddressLabel.text = R.string.localizable.aSendRecipientAddressTitle()

        targetAddressTextField.configureOnce()

        nextButton.setTitleColor(viewModel.buttonTitleColor, for: .normal)
		nextButton.backgroundColor = viewModel.buttonBackgroundColor
        nextButton.titleLabel?.font = viewModel.buttonFont
    }

}

extension TransferTokensCardViaWalletAddressViewController: QRCodeReaderDelegate {
    func readerDidCancel(_ reader: QRCodeReaderViewController!) {
        reader.stopScanning()
        reader.dismiss(animated: true, completion: nil)
    }

    func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
        reader.stopScanning()
        reader.dismiss(animated: true)

        guard let result = QRURLParser.from(string: result) else {
            return
        }
        targetAddressTextField.value = result.address
    }
}

extension TransferTokensCardViaWalletAddressViewController: AddressTextFieldDelegate {
    func displayError(error: Error, for textField: AddressTextField) {
        displayError(error: error)
    }

    func openQRCodeReader(for textField: AddressTextField) {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
            promptUserOpenSettingsToChangeCameraPermission()
            return
        }
        let controller = QRCodeReaderViewController()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }

    func didPaste(in textField: AddressTextField) {
        //Do nothing
    }

    func shouldReturn(in textField: AddressTextField) -> Bool {
        view.endEditing(true)
        return true
    }

    func didChange(to string: String, in textField: AddressTextField) {
    }
}
