//
//  SettingsView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var presentingLogin = false
    @State private var presentingCreateAccount = false
    @State private var presentingAlert = false
    
    @State private var accountCreated = false
    
    @ObservedObject var user = User.shared
    
    @State private var comController:CommunicationController!
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var newUsername = ""
    
    @State private var changesAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    if User.shared.loggedIn {
                        Section() {
                            Text("Account settings will be available in a future version. For now, please go to ringingroom.com to change your account settings.")
                            //                        Text("Current username: \(User.shared.name)")
                            //                        TextField("New username", text: $newUsername)
                        }
                        Section {
                            Toggle("Auto-rotate bell circle", isOn: .init(get: {
                                return UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
                            }, set: {
                                UserDefaults.standard.set($0, forKey: "autoRotate")
                                BellCircle.current.autoRotate = $0
                            }))
                            .toggleStyle(SwitchToggleStyle(tint: .main))
                        }
                        Section {
                            Button(action: {
                                self.presentingAlert = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Log out")
                                    Spacer()
                                }
                            }
                            .alert(isPresented: $presentingAlert) {
                                Alert(title: Text("Are you sure you want to log out?"), message: nil, primaryButton: .destructive(Text("Yes"), action: self.logout), secondaryButton: .cancel(Text("Cancel"), action: {self.presentingAlert = false}))
                            }
                        }
                    } else {
                        Text("An error has occurred. Please restart the app.")
//                        Section {
//                            Button("Log in") {
//                                self.presentingLogin = true
//                            }
//                            .sheet(isPresented: $presentingLogin, onDismiss: {
//                                print("login is dissmissed", self.presentingLogin)
//                            }) {
//                                SimpleLoginView(loggedIn: self.$loggedIn)
//                            }
//                        }
//                        Section {
//                            Button("Create account") {
//                                self.presentingCreateAccount = true
//                            }
//                            .sheet(isPresented: $presentingCreateAccount, onDismiss: {
//                                if self.accountCreated {
//                                    self.comController.login(email: self.email, password: self.password)
//                                }
//                            }) {
//                                AccountCreationView(isPresented: self.$presentingCreateAccount, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
//                            }
//                        }
                        
                    }
                }
                VStack {
                    Spacer()
                    #if DEBUG
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                            .font(.callout)
                    #else
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                            .font(.callout)
                    #endif
                    Text("By Matthew Goodship")
                        .font(.callout)
                }
                .padding()
                .foregroundColor(.secondary)
            }.navigationBarTitle("Account")
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self, loginType: .settings)
        })
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        print("status code: \(String(describing: statusCode))")
        print(responseData!)
        if statusCode! == 401 {
            print(responseData ?? "0")
            alertTitle = "Error logging in"
            self.showingAlert = true
        } else {
            comController.getUserDetails()
            comController.getMyTowers()
        }
    }
    
    @State var i = 1
    
//    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
//        if statusCode! == 401 {
//            alertTitle = "Error logging in"
//            self.showingAlert = true
//        } else {
//            DispatchQueue.main.async {
//                UserDefaults.standard.set(true, forKey: "keepMeLoggedIn")
//                UserDefaults.standard.set(self.email, forKey: "userEmail")
//                UserDefaults.standard.set(self.password, forKey: "userPassword")
//                self.loggedIn = true
//            }
//        }
//    }
//
//    func runShortcut() {
//        if i == 1 {
//            var shortcutName = "shortcuts://import-shortcut?url=https://www.icloud.com/shortcuts/04566978207b47b2a99b7b878028d431&name=Start%20Practice&silent=true"
//
//            let url = URL(string: shortcutName)!
//            UIApplication.shared.open(url,
//                                      options: [:],
//                                      completionHandler: nil)
//            i += 1
//        } else {
//            var shortcutName = "shortcuts://run-shortcut?name=Start%20Practice&silent=true"
//
//            let url = URL(string: shortcutName)!
//            UIApplication.shared.open(url,
//                                      options: [:],
//                                      completionHandler: nil)
//        }
//    }
    
    func logout() {
        let kcw = KeychainWrapper()

        do {
            try kcw.deletePasswordFor(account: User.shared.email)
        } catch {
            print("error deleting password")
        }

        User.shared = User()
        
        CommunicationController.token = nil
        UserDefaults.standard.set("", forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
                
        User.shared.loggedIn = false
        
        AppController.shared.loginState = .standard
        AppController.shared.state = .login
        print("logged out")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

extension UserDefaults {

    public func optionalInt(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }

    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
    
    public func optionalDouble(forKey defaultName: String) -> Double? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Double
        }
        return nil
    }
}
