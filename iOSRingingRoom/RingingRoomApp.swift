//
//  RingingRoomApp.swift
//  iOSRingingRoom
//
//  Created by Matthew on 19/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import SwiftUI

@main
struct RingingRoomApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    let cc = CommunicationController(sender: nil)
    
    var body: some Scene {
        WindowGroup {
            MainApp()
                .onChange(of: scenePhase, perform: { value in
                    print("refreshed token", value)
                    if value == .active {
                        cc.loginType = .refresh
                        cc.login(email: User.shared.email, password: User.shared.password)
                    }
                })
        }
    }
}

extension URL {
    var isTowerLink:Bool {
        (self.pathComponents.count > 1)
    }
    var towerID:Int? {
        if isTowerLink {
            return Int(self.pathComponents[1])
        } else {
            return nil
        }
    }
}
