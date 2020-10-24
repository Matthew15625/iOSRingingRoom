//
//  AutoLogin.swift
//  iOSRingingRoom
//
//  Created by Matthew on 05/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AutoLogin: View {
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?

    @State private var showingAlert = false
    
    @State private var comController:CommunicationController!
    
    @State private var autoJoinTower = false
    @State private var autoJoinTowerID = 0
    
    var body: some View {
        ZStack {
            Color.main
            HStack {
                Spacer(minLength: 55)
                Image("rrLogo").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 512, maxHeight: 512)
                Spacer(minLength: 55)
            }
            
        }
        .onOpenURL { url in
            guard let towerID = url.towerID else { return }
            self.autoJoinTower = true
            self.autoJoinTowerID = towerID
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showingAlert) {
        //present welcome login screen
            Alert(title: Text("Error"), message: Text("There was an error trying to log you in."), dismissButton: .cancel(Text("OK"), action: {
                self.viewControllerHolder?.present(style: .fullScreen, name: "", animated: false) {
                    WelcomeLoginScreen()
                }
            }))
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self, loginType: .auto)
            self.comController.login(email: UserDefaults.standard.string(forKey: "userEmail")!, password: UserDefaults.standard.string(forKey: "userPassword")!)
        })
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 401 {
            self.showingAlert = true
        } else {
            self.comController.getUserDetails()
            self.comController.getMyTowers()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, response:[String:Any]) {
        if statusCode == 401 {
            self.showingAlert = true
        } else {
            DispatchQueue.main.async {
                self.viewControllerHolder?.present(style: .fullScreen, name: "Main", animated: false) {
                    MainApp(autoJoinTower: autoJoinTower, autoJoinTowerID: autoJoinTowerID)
                }
            }
        }
    }
}

struct AutoLogin_Previews: PreviewProvider {
    static var previews: some View {
        AutoLogin()
    }
}
