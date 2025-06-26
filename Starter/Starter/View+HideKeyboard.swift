import SwiftUI

#if canImport(UIKit)
extension View {
    /// Dismisses the system keyboard for this application.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
