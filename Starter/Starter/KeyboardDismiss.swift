import SwiftUI

#if canImport(UIKit)
extension View {
    /// Hides the currently presented keyboard, if any.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
