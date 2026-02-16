//
//  EvidenciaCientificaModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 13/2/26.
//

import Foundation


enum EvidenciaCientificaListado : String, CaseIterable {
    case campoCuantico                                = "evi_campo_cuantico"
    case coherenciaCorazonCerebro                     = "evi_coherencia_corazon_cerebro"
    case campoMagneticoEnCorazon                      = "evi_corazon_campo_magnetico"
    case efectoEmocionSobreExpresionGenica            = "evi_emociones_afectan_expresion_genica"
    case emocionesNegativasYCoherenciaCerebral        = "evi_emociones_negativas_y_coherencia_cerebral"
    case entrelazamientoCuantico                      = "evi_entrelazamiento_cuantico"
    case membranaCelularComoProcesador                = "evi_membrana_celular_como_procesador"
    case neurogenesis                                 = "evi_neurogenesis"
    case neuronasCardiacas                            = "evi_neuronas_cardiacas"
    case neuroPlasticidad                             = "evi_neuroplasticidad"
    case nevilleYLaCiencia                            = "evi_neville_y_ciencia"
    case pensamientosInfluyenEnLaBiologia             = "evi_pensamiento_influye_biologia"
    case pensamientosLLevanEnergiaEInformacion        = "evi_pensamiento_lleva_energia_info"
    case pensamientosCambianLaAnatomia                = "evi_pensamientos_modifican_anatomia"
    case somosMasEnergiaQueMateria                    = "evi_somos_mas_energia_que_materia"
    case universoEsMental                              = "evi_universo_es_mental"
    
    var getTitle: String {
        switch self {
        case .campoCuantico:                                 return "Campo Cuántico"
        case .coherenciaCorazonCerebro:                     return "Coherencia Corazón Cerebro"
        case .campoMagneticoEnCorazon:                       return "Campo Magnético en Corazón"
        case .efectoEmocionSobreExpresionGenica:             return "Efecto de emoción sobre expresión de genes"
        case .emocionesNegativasYCoherenciaCerebral:        return "Emociones Negativas y Coherencia Cerebral"
        case .entrelazamientoCuantico:                      return "Entrelazamiento Cuántico"
        case .membranaCelularComoProcesador:               return "Membrana celular como procesador de señales"
        case .neurogenesis:                                 return "Neurogénesis"
        case .neuronasCardiacas:                           return "Neuronas Cardíacas"
        case .neuroPlasticidad:                             return "Neuroplasticidad"
        case .nevilleYLaCiencia:                           return "Neville y la ciencia"
        case .pensamientosInfluyenEnLaBiologia:             return "Los pensamientos influyen en la biología"
        case .pensamientosLLevanEnergiaEInformacion:       return "Los pensamientos portan energía e información"
        case .pensamientosCambianLaAnatomia:               return "Los Pensamientos cambian la anatomía"
        case .somosMasEnergiaQueMateria:                  return "Somos más energía que materia"
        case .universoEsMental:                            return "El universo es mental"
        }
    }
    
}
