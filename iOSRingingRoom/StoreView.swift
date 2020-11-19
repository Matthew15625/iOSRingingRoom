//
//  StoreView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct StoreView: View {
        
    let webview = Webview(web: nil, url: URL(string: "https://www.redbubble.com/people/ringingroom/shop?asc=u")!)
    
    @State var actionSheetIsPresented = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                GeometryReader { geo2 in
                    self.webview
                    .onAppear(perform: {
                        self.webview.webviewController?.webview.frame = geo2.frame(in: .local)
                    })
                }
                ZStack {
                    Color.primary.colorInvert()
                    HStack {
                        Button(action: {self.webview.goBack()}) {
                            Image(systemName: "chevron.left")
                       //         .font(.title)
                        }
                        Spacer()
                        Button(action: {self.webview.goForward()}) {
                            Image(systemName: "chevron.right")
                       //         .font(.title)
                        }
                        Spacer()
                        Button(action: {self.actionSheetIsPresented = true}) {
                            Image(systemName: "square.and.arrow.up")
                   //             .font(.title)
                        }
                        .sheet(isPresented: self.$actionSheetIsPresented) {
                            ShareSheet(activityItems: [self.webview.webviewController!.webview.url!], applicationActivities: nil)
                        }
                        Spacer()
                        Button(action: {UIApplication.shared.open((self.webview.webviewController?.webview.url)!)}) {
                            Image(systemName: "safari")
                   //             .font(.title)
                        }
                        
                    }
                    .padding()

                }
            .fixedSize(horizontal: false, vertical: true)
            }
        }
        
    }
}

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
    }
}
