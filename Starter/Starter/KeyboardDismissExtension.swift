import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    /// Dismisses the on-screen keyboard.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
