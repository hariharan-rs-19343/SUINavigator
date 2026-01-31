//
//  File.swift
//  SUINavigator
//
//  Created by Hariharan R S on 30/01/26.
//

import SwiftUI

public extension View {
    
    @ViewBuilder
    func presentable<V: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> V, dismiss: (() -> Void)?) -> some View {
        modifier(
            ZHPresentationCover(isPresented: isPresented, content: content, onDismiss: dismiss)
        )
    }
    
    @ViewBuilder
    func presentable<T, V>(item: Binding<T?>, @ViewBuilder content: @escaping (T) -> V, dismiss: (() -> Void)? = nil) -> some View where T: Equatable & Identifiable, V: View {
        modifier(
            ZHPresentationCoverItem(item: item, content: content, onDismiss: dismiss)
        )
    }
}
