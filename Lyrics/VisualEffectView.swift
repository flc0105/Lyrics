//
//  VisualEffectView.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/21.
//

import Foundation
import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        effectView.material = .dark
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

