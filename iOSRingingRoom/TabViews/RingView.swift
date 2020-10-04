//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import Combine

struct RingView: View {
    
//    init() {
//         UIScrollView.appearance().bounces = false
//    }
    
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    @State var comController:CommunicationController!

    @State var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]

    @State var towerID = UserDefaults.standard.string(forKey: "\(User.shared.email)savedTower") ?? ""
    
    @State var showingAlert = false
    @State var alertTitle = Text("")
    @State var alertMessage:Text? = nil
    
    @ObservedObject var user = User.shared
    
    @State var ringingRoomView = RingingRoomView()
    
    @State var joinTowerYPosition:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    
    @State var viewOffset:CGFloat = 0
    
    @State var isRelevant = false
    
    var body: some View {
        VStack(spacing: 20) {
//            Picker("Tower list selection", selection: $towerListSelection) {
//                ForEach(0 ..< towerLists.count) {
//                    Text(self.towerLists[$0])
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
            ScrollView {
                VStack {
//                    if User.shared.myTowers[0].tower_id != 0 {
                        ForEach(User.shared.myTowers) { tower in

                            if tower.tower_id != 0 {
                                Button(action: {self.towerID = String(tower.tower_id)}) {
                                    Text(String(tower.tower_id))
                                        .towerButtonStyle(isSelected: (String(tower.tower_id) == self.towerID), name: tower.tower_name)
                                }
                                .frame(height: 40)
                                .padding(.horizontal)
                                .buttonStyle(CustomButtonStyle())
                                .cornerRadius(10)
                            } else {
                                /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
                            }
                            //                        .contextMenu {
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                HStack {
                            //                                    Image(systemName: "bookmark")
                            //                                    Text("Favourite")
                            //                                }
                            //                            }
                            //
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                HStack {
                            //                                    Image(systemName: "gear")
                            //                                    Text("Settings")
                            //                                }
                            //                            }
                            //
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                Image(systemName: "minus.circle")
                            //                                    .accentColor(.red)
                            //                                Text("Remove")
                            //                            }
                            //                        }
                        }
//                    }
                }
            }
                TextField("Tower name or id", text: $towerID)
                    .onChange(of: towerID, perform: { _ in
                        UserDefaults.standard.set(towerID, forKey: "\(User.shared.email)savedTower")
                    })
                    .disabled(!User.shared.loggedIn)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            GeometryReader { geo in
                Button(action: self.joinTower) {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                        Text(!User.shared.loggedIn ? "Please log in to join or create a tower" : self.isID(str: self.towerID) ? "Join Tower" : "Create Tower")
                            .foregroundColor(.white)
                    }
                }
                .opacity(User.shared.loggedIn ? towerID.count != 0 ? 1 : 0.35 : 0.35)
                .disabled((User.shared.loggedIn ? towerID.count != 0 ? false : true : true))
                .onAppear(perform: {
                    var pos = geo.frame(in: .global).midY
                    pos += geo.frame(in: .global).height/2 + 10
                    print("pos", pos)
                    pos = UIScreen.main.bounds.height - pos
                    self.joinTowerYPosition = pos
                })
                    .alert(isPresented: self.$showingAlert) {
                        Alert(title: self.alertTitle, message: self.alertMessage, dismissButton: .cancel(Text("OK")))
                }
            }
            .frame(height: 45)
            .fixedSize(horizontal: false, vertical: true)
            
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self)
        })
            .padding()
    }
    
    func getOffset() -> CGFloat {
        
        let offset = keyboardHeight - joinTowerYPosition
        print("offset: ",offset)
        if offset <= 0 {
            return 0
        } else {
            return -offset
        }
    }
    
    func isID(str:String) -> Bool {
        if str.count == 9 {
            if Int(str) != nil {
                return true
            }
        }
        return false
    }
    
    func joinTower() {
        print("joined tower")
        if isID(str: self.towerID) {
            self.getTowerConnectionDetails()
            return
        }
        
        //create new tower
        comController.createTower(name: self.towerID)
        
        
    }
    
    func getTowerConnectionDetails() {
        comController.getTowerDetails(id: Int(self.towerID)!)
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 404 {
            self.alertTitle = Text("There is no tower with that ID")
            self.showingAlert = true
        } else {
            print("presenting rrView")
            DispatchQueue.main.async {
                self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
                    self.ringingRoomView
                }
            }
        }
    }
    
}

struct towerButtonModifier:ViewModifier {
    var isSelected:Bool
    var name:String
    
    func body(content: Content) -> some View {
            HStack() {
                Text(name)
                .fontWeight(isSelected ? Font.Weight.bold : nil)
                content
                Spacer()
            }
            .foregroundColor(isSelected ? .main : Color.primary)
    }
}

struct CustomButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .opacity(1)
        .contentShape(Rectangle())
    }
}

extension View {
    func towerButtonStyle(isSelected:Bool, name:String) -> some View {
        self.modifier(towerButtonModifier(isSelected: isSelected, name: name))
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
