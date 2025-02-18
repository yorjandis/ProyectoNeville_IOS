
import SwiftUI
import CoreData


struct ContentView: View{
    @State var showSheetDiario = false
    @State var showSheetNotas = false
    
    var body: some View{
        
        
        
        Home()
            .onOpenURL(perform: { url in
                switch url.description{
                    case AppCons.DeepLink_url_Diario : showSheetDiario = true
                    case AppCons.DeepLink_url_Notas :  showSheetNotas = true
                    default : break
                }
            })
            .sheet(isPresented: $showSheetDiario, content: {
                DiarioListView()
            })
            .sheet(isPresented: $showSheetNotas, content: {
                ListNotasViews()
            })
        
    }
    


}//struct




#Preview {
    ContentView()
}
