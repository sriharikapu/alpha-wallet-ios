// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

struct SellTokensCardViewModel {
    let token: TokenObject
    let tokenHolders: [TokenHolder]

    init(token: TokenObject) {
        self.token = token
        self.tokenHolders = TokenAdaptor(token: token).getTokenHolders()
    }

    func item(for indexPath: IndexPath) -> TokenHolder {
        return tokenHolders[indexPath.row]
    }

    func numberOfItems(for section: Int) -> Int {
        return tokenHolders.count
    }

    var title: String {
        let tokenTypeName = XMLHandler(contract: token.address.eip55String).getTokenTypeName()
        return R.string.localizable.aWalletTokenSellSelectTokensTitle(tokenTypeName)
    }

    var buttonTitleColor: UIColor {
        return Colors.appWhite
    }

    var buttonBackgroundColor: UIColor {
        return Colors.appHighlightGreen
    }

    var buttonFont: UIFont {
        return Fonts.regular(size: 20)!
    }

    func toggleSelection(for indexPath: IndexPath) -> [IndexPath] {
        let tokenHolder = item(for: indexPath)
        var changed = [indexPath]
        if tokenHolder.areDetailsVisible {
            tokenHolder.areDetailsVisible = false
            tokenHolder.isSelected = false
        } else {
            for (i, each) in tokenHolders.enumerated() where each.areDetailsVisible {
                each.areDetailsVisible = false
                each.isSelected = false
                changed.append(.init(row: i, section: indexPath.section))
            }
            tokenHolder.areDetailsVisible = true
            tokenHolder.isSelected = true
        }
        return changed
    }
}
