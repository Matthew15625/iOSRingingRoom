//
//  SimpleLoginView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct SimpleLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var comController:CommunicationController!

    @State var email = ""
    @State var password = ""
    @State var stayLoggedIn = false
    
    @Binding var loggedIn:Bool
    
    @State var validEmail = false
    @State var validPassword = false
    
    var loginDisabled:Bool {
        get {
            !(validEmail && validPassword)
        }
    }
    
    @State var showingAccountCreationView = false
    @State var showingResetPasswordView = false
                
    @State private var accountCreated = false
    
    @State var showingAlert = false
    @State var alertTitle = Text("")
    @State var alertMessage:Text? = nil
        
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                TextField("Email", text: $email)
                .onChange(of: email, perform: { _ in
                    validEmail = email.trimmingCharacters(in: .whitespaces).isValidEmail()
                })
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: self.$password)
                    .onChange(of: password, perform: { _ in
                        validPassword = password.count > 0
                    })
                    .textContentType(.password)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Toggle(isOn: $stayLoggedIn) {
                    Text("Keep me logged in")
                }
                .padding(.vertical, 7)
                Button(action: login) {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                            .opacity(loginDisabled ? 0.35 : 1)
                        Text("Login")
                            .foregroundColor(Color(.white))
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: self.alertTitle, message: self.alertMessage, dismissButton: .default(Text("OK")))
                }
                .frame(height: 43)
                .disabled(loginDisabled)
                Spacer()
                HStack(alignment: .center, spacing: 0.0) {
                    Button(action: {self.showingResetPasswordView = true}) {
                        Text("Forgot password?")
                            .font(.footnote)
                    }.sheet(isPresented: $showingResetPasswordView) {
                        resetPasswordView(isPresented: self.$showingResetPasswordView, email: self.$email)
                    }
                    
                    Spacer()
                    Button(action: { self.showingAccountCreationView = true } ) {
                        Text("Create an account")
                            .font(.footnote)
                    }.sheet(isPresented: $showingAccountCreationView, onDismiss: {if self.accountCreated {self.login()}}) {
                        AccountCreationView(isPresented: self.$showingAccountCreationView, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                    }
                }
                .foregroundColor(Color(red: 178/255, green: 39/255, blue: 110/255))
            }
            .padding()
            .navigationBarItems(leading: Button("Back") {self.presentationMode.wrappedValue.dismiss()})
            .navigationBarTitle("Login", displayMode: .inline)
        }
    .onAppear(perform: {
        self.comController = CommunicationController(sender: self, loginType: .simple)
    })
    }
    
    
    
    func login() {
        comController.login(email: self.email.trimmingCharacters(in: .whitespaces), password: self.password)
        //send login request to server
  //     presentMainApp()
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            print(responseData ?? 0)
            alertTitle = Text("Your email or password is incorrect")
            self.showingAlert = true
        } else {
            DispatchQueue.main.async {
                self.comController.getUserDetails()
                self.comController.getMyTowers()
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            alertTitle = Text("Error")
            self.showingAlert = true
        } else {
            UserDefaults.standard.set(self.stayLoggedIn, forKey: "keepMeLoggedIn")
            UserDefaults.standard.set(self.email, forKey: "userEmail")
            UserDefaults.standard.set(self.password, forKey: "userPassword")
            UserDefaults.standard.set(0, forKey: "selectedTower")
            self.loggedIn = true
//            self.presentationMode.wrappedValue.dismiss()
//            print("tried to dismiss")
        }
    }
    
}
