//
//  YTModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Crea una instancia de un reproductor de medios de youtube

import SwiftUI
import WebKit

struct VideoViewModel : UIViewRepresentable{
    //Id de Youtube
    let youtubeID : String
    
    func makeUIView(context: Context) -> some WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
        guard let URLVideo = URL(string: "https://www.youtube.com/embed/\(youtubeID)") else {return}
        
       // uiView.scrollView.isScrollEnabled = false
        
        uiView.load(URLRequest(url: URLVideo))
        
        
       
    }

}


