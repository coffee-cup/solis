//
//  PermissionController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 21/10/2019.
//  Copyright © 2019 Puddllee. All rights reserved.
//

import SPPermission

class PermissionController: SPPermissionDialogDataSource {
    var dialogTitle: String { return "Permission Request" }
    var dialogSubtitle: String { return "" }
    var dialogComment: String { return "" }
    var allowTitle: String { return "Allow" }
    var allowedTitle: String { return "Allowed" }
    var bottomComment: String { return "" }
}
