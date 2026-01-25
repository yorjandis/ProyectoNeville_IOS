//
//  EciclopediaModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/1/26.
//

import Foundation



enum EnciclopediaTemas: String, CaseIterable {
    case CoherenciaCardioCerebral                   = "Coherencia Cardio-Cerebral"
    
    case Epigenética                                = "La Epigenética"
    case HormonasStress                             = "Las Hormonas del Estres"
    case Meditación                                 = "La Meditación"
    case MenteUniversal                             = "La Mente Universar/Campo Cuántico/Matríz Divina"
    
    case MenteConcienteYSubconciente                = "La Mente Consciente y Subconciente"
    case Conciencia                                 = "La Conciencia"
    case Tiempo                                     = "El Concepto de Tiempo"
    case EntrelazamientoCuanticoNeurociencia        = "El Entralazamiento Cuántico desde la Neurociencia"
    case Enfermedad                                 = "La enfermedad"
    case MeditacionYExpresionGenica                 = "Meditación y Expresión Génica"
   
    //Pensamientos & Sentimientos:
    case EfectosSentimientosNegativos               = "Efectos Sentimientos Negativos"
    case SentimientoComoFuerzaCreadora              = "El Sentimiento como fuerza creadora"
    case PensamientosSentimientosSistemaInmune      = "Los Pensamientos-Sentimientos y el sistema inmunológico"
    case QueEsUnPensamiento                         = "Qué es un Pensamiento"
    
    //Habitos:
    case NeurocienciaDeLosHabitos                   = "La Neurociencia de los Hábitos"
    case HabitosYAhorroDeEnergia                    = "Habitos y Ahorro de Energía Cerebral"
    case RomperUnHabito                             = "Cómo Romper un Hábito Fisiológicamente"
    case CuantoTardaEnDebilitarseUnHábito           = "Cuanto Tarda un Hábito en Debilitarse?"
    case RecaerNoInterrumpeElProgreso               = "Porqué Recaer no Interrumpe el progreso de un Hábito?"
    case UtilizarRecaidaATuFavor                    = "Utilizar una Recaída a Tu favor"
    case ProtocoloAntiRecaída                       = "Protocolo Antirecaída"
    case SeñalConsolidacionHabito                   = "Señales de Consolidación de un Hábito"
    case ListadoDeHabitosSaludables                 = "Listado de Hábitos Saludables"
    
     var getFileName : String {
        switch self{  
        case .CoherenciaCardioCerebral:             "enc_coherencia_cardiocerebral"
        
        case .Epigenética:                          "enc_epigenetica"
        case .HormonasStress:                       "enc_hormonas_estres"
        case .Meditación:                           "enc_meditacion"
        case .MenteUniversal:                       "enc_mente_universal"
        
        case .MenteConcienteYSubconciente:          "enc_menteconciente_subconciente"
        case .Conciencia:                           "enc_conciencia"
        case .Tiempo:                               "enc_tiempo"
        case .EntrelazamientoCuanticoNeurociencia:  "enc_entrelazamiento_cuantico_neurociencia"
        case .Enfermedad:                           "enc_enfermedad"
        case .MeditacionYExpresionGenica:           "enc_meditacion_y_expresiongenica"
        
        //Pensamientos & Sentimientos
        case .QueEsUnPensamiento:                   "enc_que_es_un_pensamiento"
        case .PensamientosSentimientosSistemaInmune:"enc_pensamientos_emociones_sistemainmune"
        case .SentimientoComoFuerzaCreadora:        "enc_sentimiento_como_fuerzacreativa"
        case .EfectosSentimientosNegativos:         "enc_efecto_sentimie_negativos"
          
            
            
        //Hábitos:
        case .NeurocienciaDeLosHabitos:             "enc_neurociencia_habitos"
        case .HabitosYAhorroDeEnergia:              "enc_habitos_y_ahorroenergia_cerebral"
        case .RomperUnHabito:                       "enc_romper_un_habito"
        case .CuantoTardaEnDebilitarseUnHábito:     "enc_cuanto_tarda_habito_debilitarse"
        case .RecaerNoInterrumpeElProgreso:         "enc_recaer_no_interrumpe_progreso"
        case .UtilizarRecaidaATuFavor:              "enc_utilizar_recaida_a_tu_favor"
        case .ProtocoloAntiRecaída:                 "enc_protocolo_antirecaida"
        case .SeñalConsolidacionHabito:             "enc_señales_consolidacion_habito"
        case .ListadoDeHabitosSaludables:           "enc_listado_habitos_saludables"
        }
         
    }
}


//Categorias de Temas

extension EnciclopediaTemas {
    
    static var temasGenerales: [EnciclopediaTemas] {
        return [
            .CoherenciaCardioCerebral,
            .EfectosSentimientosNegativos,
            .Epigenética,
            .HormonasStress,
            .Meditación,
            .MenteUniversal,
            .SentimientoComoFuerzaCreadora,
            .MenteConcienteYSubconciente,
            .Conciencia,
            .Tiempo,
            .EntrelazamientoCuanticoNeurociencia,
            .Enfermedad,
            .MeditacionYExpresionGenica
            
        ]
    }
    
    
    static var pensamientoYSentimientos : [EnciclopediaTemas]{
        return [
            .QueEsUnPensamiento,
            .EfectosSentimientosNegativos,
            .SentimientoComoFuerzaCreadora,
            .PensamientosSentimientosSistemaInmune
        ]
    }
    
    static var habitos: [EnciclopediaTemas] {
            return [
                .NeurocienciaDeLosHabitos,
                .HabitosYAhorroDeEnergia,
                .RomperUnHabito,
                .CuantoTardaEnDebilitarseUnHábito,
                .RecaerNoInterrumpeElProgreso,
                .UtilizarRecaidaATuFavor,
                .ProtocoloAntiRecaída,
                .SeñalConsolidacionHabito,
                .ListadoDeHabitosSaludables
                
            ]
        }
        
        
}
