//
//  galeriaFotos.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/9/23.
//

import SwiftUI

struct galeriaFotosView: View {
    var body: some View {
        NavigationStack{
            ScrollView {
                ForEach (1..<18){idx in
                    VStack {
                        Image("\(idx)")
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 200, height: 200)
                            .cornerRadius(20)
                            .shadow(color: .black, radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/, x: 2, y: 0)
                        Text(descriptions[idx] ?? "")
                            .multilineTextAlignment(.center)
                    }
                    
                    .padding(.vertical, 1)
                }
            }
            .padding()
        }
    }
    
    let descriptions : [Int:String] = [6:"Margaret Ruth Broome y Neville Goddard en una foto de 1971, poco antes de su muerte. Margaret Broome fue una de las estudiantes de Neville y tiene 2 libros en los que compiló muchas de sus conferencias",
                                       7:"Joseph Nathaniel Goddard (padre de Neville y Victor) y Victor (hermano de Neville).",
                                       8:"Este disco de vinilo, simplemente llamado `Neville`, pertenece a su segundo álbum que salió a la venta en 1960. El disco era rojo y no del habitual color negro que casi todos conocemos. Por una cara estaba la grabación titulada `A Mystical Experience` y por la otra `Secret Of Imagining`",
                                       9:"Foto tomada a Neville Goddard sobre el año 1970 después de una de sus conferencias en el Ebell Theater de Los Angeles, CA. Créditos: Pati Springmeyer",
                                       10:"Neville Goddard y (según Pati Springmeyer) su esposa `Bill`, que siempre le acompañaba y asistía en sus conferencias. La foto muy posiblemente sea de principios de los 70's. Desconozco quién es el niño. La hija de Neville en ese tiempo ya debía ser una veinteañera o treintañera, así que no puede ser ella.Créditos: Pati Springmeyer",
                                       11:"Los Goddard en Barbados. La foto está fechada entre 1930 y 1935. Neville es el primero empezando por la derecha",
                                       12:"Dedicatoria y firma de Neville en uno de sus libros a un tal Boby. `Asume la sensación del deseo cumplido´",
                                       13:"Dedicatoria y firma de Neville en uno de sus libros a una tal Dorothy. `Para Dorothy. Sabes que esto funciona. Sigue con ello´",
                                       14:"Al parecer la tumba de Neville Goddard. (¿Finalmente su cuerpo no fue incinerado como él deseaba?)Localización: Parroquia de Saint Michael, Bridgetown, Barbados.Créditos: Rev. Eddie Rodriguez",
                                       15:"Los Goddard al completo en Barbados en la Navidad de 1933 aprox. Neville es el segundo empezando por la izquierda",
                                       16:"Los Goddard en Barbados. La foto está fechada entre 1950 y 1960 aprox. Neville es el tercero empezando por la izquierda"
                                       
                                       
    
    ]
    
    
    
}

#Preview {
    galeriaFotosView()
}
