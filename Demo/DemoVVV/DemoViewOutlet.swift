//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit

final class DemoViewOutlet: NSObject
{
    private(set) lazy var loadingItem: UIBarButtonItem = {
        let loading = UIActivityIndicatorView(style: .gray)
        loading.startAnimating()
        return UIBarButtonItem(customView: loading)
    }()

    private(set) lazy var updateItem: UIBarButtonItem = {
        UIBarButtonItem(title: "更新", style: .plain, target: nil, action: nil)
    }()
}
