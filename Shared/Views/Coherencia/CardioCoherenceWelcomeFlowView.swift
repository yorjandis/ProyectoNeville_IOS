#if os(iOS)
import SwiftUI

struct CardioCoherenceWelcomeFlowView: View {
    var body: some View {
        CardioCoherenceMainView()
    }
}
#else
import SwiftUI

struct CardioCoherenceWelcomeFlowView: View {
    var body: some View {
        EmptyView()
    }
}
#endif
