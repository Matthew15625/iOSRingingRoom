//
//  myManager.swift
//  NativeRingingRoom
//
//  Created by Matthew on 01/08/2020.
//  Copyright © 2020 Matthew. All rights reserved.
//

import Foundation
import SocketIO
import Combine

class SocketIOManager: NSObject, ObservableObject {
    static var shared = SocketIOManager()
    
    var socket:SocketIOClient?
    
    var manager:SocketManager!
    
    var bellCircle = BellCircle.current
        
    var refresh = false
    var server_ip = ""
    
    var cc = CommunicationController(sender: self)
    
    var gotAnAssignment = false
    
    var setups = 0 {
        didSet {
            if setups == 7 {
                
                print("finished setup", setups)
                AppController.shared.state = .ringing
                cc.getMyTowers()
            }
        }
    }
    
    func connectSocket(server_ip:String) {
        self.server_ip = server_ip
        manager = SocketManager(socketURL: URL(string: server_ip)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        addListeners()
        socket?.connect()
        print(bellCircle.towerID)
    }
    
    func gotMyTowers() {
        if bellCircle.needsTowerInfo {
            if let tower = User.shared.myTowers.towerForID(bellCircle.towerID) {
                bellCircle.isHost = tower.host
                bellCircle.needsTowerInfo = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.cc.getMyTowers()
                }
            }
        }
    }
    
    func addListeners() {
        socket?.onAny() { data in
            if !(data.event == "ping" || data.event == "pong") {
                print("received socketio event: ", data.event)
                print(data.items)
            }
        }

//
        socket?.on(clientEvent: .connect) { data, ack in
            print(self.socket?.status)
            self.socket?.emit("c_join", ["tower_id": self.bellCircle.towerID, "user_token": CommunicationController.token!, "anonymous_user": false])
            if self.bellCircle.needsTowerInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.cc.getMyTowers()
                }
            } else {
//                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
//                    if AppController.shared.state != .ringing {
//                        self.setups = 0
//                        self.socket?.disconnect()
//                        self.socket?.connect()
//                    }
//                }
            }
        }
        
        socket?.on("s_size_change") { data, ack in
            if self.refresh {
                self.socket?.emit("c_request_global_state", ["tower_id":self.bellCircle.towerID])
            }
            if AppController.shared.state != .ringing {
                print("from size change")
                self.setups += 1
                self.socket?.emit("c_request_global_state", ["tower_id":self.bellCircle.towerID])
            }
            self.bellCircle.newSize(self.getDict(data)["size"] as! Int)

        }
        
        socket?.on("s_global_state") { data, ack in
            if AppController.shared.state != .ringing {
                print("from bell states")
                self.setups += 1
            }
            self.bellCircle.objectWillChange.send()
            self.bellCircle.bellStates = self.getDict(data)["global_bell_state"] as! [Bool]
        }
        
        socket?.on("s_bell_rung") { data, ack in
            print(self.bellCircle.counter)
            self.bellCircle.bellRang(number: self.getDict(data)["who_rang"] as! Int, bellStates: self.getDict(data)["global_bell_state"] as! [Bool])
        }
        
        socket?.on("s_call") { data, ack in
            print(self.getDict(data)["call"] as! String)
            self.bellCircle.callMade(self.getDict(data)["call"] as! String)
        }
        
        socket?.on("s_set_userlist") { data, ack in
            if AppController.shared.state != .ringing {
                print("from userlist")
                self.setups += 1
            }
            self.bellCircle.newUserlist(self.getDict(data)["user_list"] as! [[String:Any]])
        }
        
        socket?.on("s_assign_user") { data, ack in
            if AppController.shared.state != .ringing {
                self.gotAnAssignment = true
            }
            let id = self.getDict(data)["user"] as? Int
            let bell = self.getDict(data)["bell"] as! Int
            if id != nil {
                if id == 0 {
                    self.bellCircle.unAssign(at: bell)
                } else {
                    self.bellCircle.assign(id!, to: bell)
                }
            } else {
                self.bellCircle.unAssign(at: bell)
            }
        }
        
        socket?.on("s_user_entered") { data, ack in
            if AppController.shared.state != .ringing {
                User.shared.ringerID = self.getDict(data)["user_id"] as! Int
                print("set userID")
                print("from user entered")
                self.setups += 1
            }
            print(self.getDict(data))
            self.bellCircle.newUser(id: self.getDict(data)["user_id"] as! Int, name: self.getDict(data)["username"] as! String)
        }
        
        socket?.on("s_audio_change") { data, ack in
            if AppController.shared.state != .ringing {
                print("from audio change")
                self.setups += 1
            }
            self.bellCircle.newAudio(self.getDict(data)["new_audio"] as! String)
        }
        
        socket?.on("s_host_mode") { data, ack in
            if AppController.shared.state != .ringing {
                print("from host mode")
                self.setups += 1
            }
            self.bellCircle.hostModeEnabled = self.getDict(data)["new_mode"] as! Bool
        }
        
        socket?.on("s_msg_sent") { data, ack in
            ChatManager.shared.newMessage(user: self.getDict(data)["user"] as! String, message: self.getDict(data)["msg"] as! String)
        }
        
        socket?.on("s_user_left") { data, ack in
            print(self.getDict(data))
            if self.getDict(data)["user_id"] as! Int == User.shared.ringerID {
                self.leaveTower()
            } else {
                self.bellCircle.userLeft(id: self.getDict(data)["user_id"] as! Int)
            }
        }
    }
    
    func getDict(_ array:[Any]) -> [String:Any] {
        let data = array[0] as! [String:Any]

        return data
    }
    
    func leaveTower() {
        socket?.emit("c_user_left", ["user_name":User.shared.name, "user_token":CommunicationController.token!, "anonymous_user":false, "tower_id":bellCircle.towerID])
        setups = 0
//        bellCircle.setupComplete = ["gotUserList":false, "gotSize":false, "gotAudioType":false, "gotHostMode":false, "gotUserEntered":false, "gotBellStates":false, "gotAssignments":false]
        socket?.disconnect()
        bellCircle.users = [Ringer]()
        bellCircle.gotAssignments = false
        bellCircle.isLargeSize = false

        socket = nil
        ChatManager.shared.messages = [Message]()
        ChatManager.shared.newMessages = 0
        ChatManager.shared.canSeeMessages = false
        manager = nil
        
        gotAnAssignment = false
        
        print(User.shared.myTowers.names)
        
        AppController.shared.state = .main

    }
    
    func getStatus() {
        print(socket?.status)
    }
    
}
