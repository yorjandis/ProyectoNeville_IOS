
import SwiftUI
import CoreData


struct ContentView: View{
    
    @EnvironmentObject private var settingModel: SettingModel
    
    @State var showSheetDiario = false
    @State var showSheetNotas = false
    
    
    
    
    
    //Codigo a cargar al inicio:
    init(){
        //Carga los valores de Setting para Userdefault si es la primera vez
        if UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize) == 0 {
            SettingModel().setValuesByDefault()
        } 
    }
    
    
    
    
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
