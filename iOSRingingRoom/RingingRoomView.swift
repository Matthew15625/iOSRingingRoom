//
//  RingingRoomView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 08/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import AVFoundation


struct RingingRoomView: View {
    var towerParameters:TowerParameters? = nil
        
    @ObservedObject var bellCircle:BellCircle = BellCircle()
        
    @State var setupComplete = false
    
    
    
    @State var audioPlayer:AVAudioPlayer?
        
    @State var Manager:SocketIOManager!
        
    var body: some View {
        ZStack {
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all) //background view
            VStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        ZStack() {
                            ForEach(self.bellCircle.bells) { bell in
                                if self.bellCircle.bellPositions.count == self.bellCircle.size {
                                    Button(action: self.ringBell(number: bell.number)) {
                                        HStack(spacing: CGFloat(6-self.bellCircle.size) - ((self.bellCircle.bellType == .hand) ? 1 : 0)) {
                                            Text(String(bell.number))
                                                .opacity((bell.side == .left) ? 1 : 0)
                                            Image(self.getImage(bell.number)).resizable()
                                               .aspectRatio(contentMode: ContentMode.fit)
                                                .frame(height: self.bellCircle.bellType == .hand ?  58 : 75)
                                                .rotation3DEffect(.degrees(self.bellCircle.bellType == .hand ? (bell.side == .left) ? 0 : 180 : 0), axis: (x: 0, y: 1, z: 0))
                                            Text(String(bell.number))
                                                .opacity((bell.side == .right) ? 1 : 0)
                                        }
                                    }.buttonStyle(touchDown())
                                    .position(self.bellCircle.bellPositions[bell.number-1])
                                }
                            }
                            GeometryReader { scrollGeo in
                                ScrollView(.vertical, showsIndicators: true) {
                                    ForEach(self.bellCircle.bells) { bell in
                                        Text((self.bellCircle.assignments[bell.number - 1] == "") ? "" : "\(bell.number) \(self.bellCircle.assignments[bell.number - 1])")
                                            .font(.callout)
                                        .frame(maxWidth: geo.frame(in: .global).width - 100, alignment: .leading)
                                    }
                                }.id(UUID().uuidString)
                                .frame(maxHeight: geo.frame(in: .global).height - 230)
                                .fixedSize(horizontal: true, vertical: true)
                                    .position(self.bellCircle.center)
                            }
                        }
                        Button(action: {print("menu")}) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.black)
                        }
                        .padding()
                    }
                    .onAppear(perform: {
                        let height = geo.frame(in: .global).height
                        let width = geo.frame(in: .global).width
                        
                        self.bellCircle.baseRadius = width/2
                        
                        self.bellCircle.center = CGPoint(x: width/2, y: height/2)
                        
                        self.setupComplete = true
                    })
                }
                Button(action: leaveTower) {
                    Text("Leave Tower")
                }
                VStack {
                    HStack {
                        Button(action: self.makeCall("Bob")) {
                            ZStack {
                                Color.white
                                Text("Bob")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        
                        Button(action: self.makeCall("Single")) {
                            ZStack {
                                Color.white
                                Text("Single")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("That's all")) {
                            ZStack {
                                Color.white
                                Text("That's all")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                    }
                    .frame(maxHeight: 35)
                    HStack {
                        Button(action: self.makeCall("Look to")) {
                            ZStack {
                                Color.white
                                Text("Look to")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("Go")) {
                            ZStack {
                                Color.white
                                Text("Go next time")
                                    .foregroundColor(.black)
                                    .truncationMode(.tail)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("Stand next")) {
                            ZStack {
                                Color.white
                                Text("Stand next")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                    }
                    .frame(maxHeight: 35)
                    
                    HStack {
                        ForEach(self.bellCircle.bells.reversed()) { bell in
                       //     if !self.towerParameters.anonymous_user {
                            if self.bellCircle.assignments[bell.number - 1] == self.towerParameters!.cur_user_name {
                                    Button(action: self.ringBell(number: (bell.number))) {
                                        ZStack {
                                            Color.primary.colorInvert()
                                            Text("\(bell.number)")
                                                .foregroundColor(.primary)
                                                .bold()
                                        }
                                    }
                                    .cornerRadius(5)
                                .buttonStyle(touchDown())
                            }
                        }
                    }
                    .frame(maxHeight: 70)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .onAppear(perform: {
            if !(self.towerParameters == nil) {
                self.bellCircle.size = self.towerParameters!.size
                
                self.towerParameters!.cur_user_name = "Matthew Goodship"
                self.bellCircle.assignments = self.towerParameters!.assignments
                print("before connecting to new tower size = ", self.bellCircle.bells.count)
                
                self.connectToTower()
            }
        })
    }
    
    struct touchDown:PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration
                .label
                .onLongPressGesture(minimumDuration: 0) {
                    configuration.trigger()
                    
            }
        }
    }
    
    func leaveTower() {
        Manager.socket.emit("c_user_left",
                            ["user_name": towerParameters!.cur_user_name!,
                             "user_token": towerParameters!.user_token!,
                             "anonymous_user": towerParameters!.anonymous_user!,
                             "tower_id": towerParameters!.id!])
        Manager.socket.disconnect()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
    }
    
    func connectToTower() {
        initializeManager()
        initializeSocket()
        joinTower()
    }
    
    func initializeManager() {
        Manager = SocketIOManager(server_ip: towerParameters!.server_ip)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        
        Manager.connectSocket()
        
        //  Manager.getStatus()
    }
    
    func joinTower() {
        Manager.socket.emit("c_join", ["tower_id":towerParameters!.id, "anonymous_user":towerParameters!.anonymous_user])
    }
    
    
    func ringBell(number:Int) -> () -> () {
        return {
            self.bellCircle.bells[number-1].stroke.toggle()
            self.Manager.socket.emit("c_bell_rung", ["bell": number, "stroke": self.bellCircle.bells[number-1].stroke.rawValue ? "handstroke" : "backstroke", "tower_id": self.towerParameters!.id])
            self.play(Bell.sounds[self.bellCircle.bellType]![self.bellCircle.size]![number-1].prefix((self.bellCircle.bellType == .hand) ? "H" : "T"), inDirectory: "RingingRoomAudio")
        }
    }
    
    func makeCall(_ call:String) -> () -> () {
        return {
            self.Manager.socket.emit("c_call", ["call": call, "tower_id": self.towerParameters!.id])
            self.play(call, inDirectory: "RingingRoomAudio")
        }
    }
    
    func getImage(_ number:Int) -> String {
        var imageName = ""
        
        if bellCircle.bellType == .tower {
            imageName += "t"
        } else {
            imageName += "h"
        }
        
        if bellCircle.bells[number-1].stroke == .handstoke {
            imageName += "-handstroke"
            
            if number == 1 {
                imageName += "-treble"
            }
            
        } else {
            imageName += "-backstroke"
        }
        
        
        
        return imageName
    }
    
    
    
    func play(_ fileName:String, inDirectory directory:String? = nil) {
        if let path = Bundle.main.path(forResource: fileName, ofType: ".m4a", inDirectory: directory) {

            self.audioPlayer = AVAudioPlayer()

            let url = URL(fileURLWithPath: path)

            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            }catch {
                print("Error")
            }
        }
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        (self * CGFloat.pi)/180
    }
}

extension String {
    mutating func prefix(_ prefix:String) -> String {
        return prefix + self
    }
}
