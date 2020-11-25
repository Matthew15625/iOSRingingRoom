//
//  forgotPasswordView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct resetPasswordView: View {
    
    @Binding var isPresented:Bool
    @Binding var email:String
        
    @State private var isPresentingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                }
                Section {
                    Button("Not Available Yet. Please go to ringingroom.com to change your password.") {
                        self.resetPassword()
                    }
                    .alert(isPresented: $isPresentingAlert) {
                        Alert(title: Text("Email not valid"), message: Text("Please enter a valid email"))
                    }
                .disabled(true)
                }
            }
            .navigationBarTitle("Reset Password", displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") {self.isPresented = false})
        }
    .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func resetPassword() {
        if !email.trimmingCharacters(in: .whitespaces).isValidEmail() {
            isPresentingAlert = true
            return
        } else {
            //send reset password request to server
        }
    }
}
