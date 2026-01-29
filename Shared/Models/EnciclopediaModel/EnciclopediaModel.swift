//
//  EciclopediaModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/1/26.
//

import Foundation



enum EnciclopediaTemas: String, CaseIterable {
    //Temas generales:
    case coherenciaCardioCerebral                   = "Coherencia Cardio-Cerebral"
    case hormonasStress                             = "Las Hormonas del Estres"
    case meditación                                 = "La Meditación"
    case menteUniversal                             = "La Mente Universar/Campo Cuántico/Matríz Divina"
    case menteConcienteYSubconciente                = "La Mente Consciente y Subconciente"
    case conciencia                                 = "La Conciencia"
    case tiempo                                     = "El Concepto de Tiempo"
    case entrelazamientoCuanticoNeurociencia        = "El Entralazamiento Cuántico desde la Neurociencia"
    case enfermedad                                 = "La enfermedad"
    case meditacionYExpresionGenica                 = "Meditación y Expresión Génica"
    case patronesSinapticosHeredados                = "Patrones sinápticos heredados/preformados"
    case patronesConductaHeredados                  = "Patrones de Conducta Heredados"
    case atencionFocalizada                         = "La Atención Focalizada"
    case atencionFocalizadaPractica                 = "Ejercicios de Atención Focalizada"
    case apredizajeAsociativo                       = "Aprendizaje Asociativo"
    case modificarAsociacionesNoDeseadas            = "Modificación de Asociaciones No Deseadas"
   
    //Pensamientos & Sentimientos:
    case efectosSentimientosNegativos               = "Efectos Sentimientos Negativos"
    case sentimientoComoFuerzaCreadora              = "El Sentimiento como fuerza creadora"
    case pensamientosSentimientosSistemaInmune      = "Los Pensamientos-Sentimientos y el sistema inmunológico"
    case queEsUnPensamiento                         = "Qué es un Pensamiento"
    
    //Habitos:
    case neurocienciaDeLosHabitos                   = "La Neurociencia de los Hábitos"
    case habitosYAhorroDeEnergia                    = "Habitos y Ahorro de Energía Cerebral"
    case romperUnHabito                             = "Cómo Romper un Hábito Fisiológicamente"
    case cuantoTardaEnDebilitarseUnHábito           = "Cuanto Tarda un Hábito en Debilitarse?"
    case recaerNoInterrumpeElProgreso               = "Porqué Recaer no Interrumpe el progreso de un Hábito?"
    case utilizarRecaidaATuFavor                    = "Utilizar una Recaída a Tu favor"
    case protocoloAntiRecaída                       = "Protocolo Antirecaída"
    case señalConsolidacionHabito                   = "Señales de Consolidación de un Hábito"
    case listadoDeHabitosSaludables                 = "Listado de Hábitos Saludables"
    
    //Epigenética:
    case epigeneticaSegunVariosAutores              = "La Epigenética según Varios Autores"
    case epigeneticaYNeurociencia                   = "Epigenética y Neurociencia"
    case nevilleYepigenetica                        = "Neville y la Epigenética"
    case joeDispensaYEpigenetica                    = "Joe Dispensa y Epigenética"
    
    //Memoria:
    case queEsLaMemoria                            = "Qué es la Memoria"
    case memoriaSemantica                          = "Memoria Semántica"
    case memoriaEpisodica                          = "Memoria Episódica"
    case memoriaProcedimental                      = "Memoria Procedimental"
    
    
     var getFileName : String {
        switch self{
            //Temas Generales:
        case .coherenciaCardioCerebral:             "enc_coherencia_cardiocerebral"
        case .hormonasStress:                       "enc_hormonas_estres"
        case .meditación:                           "enc_meditacion"
        case .menteUniversal:                       "enc_mente_universal"
        case .menteConcienteYSubconciente:          "enc_menteconciente_subconciente"
        case .conciencia:                           "enc_conciencia"
        case .tiempo:                               "enc_tiempo"
        case .entrelazamientoCuanticoNeurociencia:  "enc_entrelazamiento_cuantico_neurociencia"
        case .enfermedad:                           "enc_enfermedad"
        case .meditacionYExpresionGenica:           "enc_meditacion_y_expresiongenica"
        case .patronesSinapticosHeredados:          "enc_patrones_sinapticos_heredados"
        case .patronesConductaHeredados:            "enc_patrones_de_conducta_heredados"
        case .atencionFocalizada:                   "enc_atencion_focalizada"
        case .atencionFocalizadaPractica:           "enc_atencion_focalizada_practica"
        case .apredizajeAsociativo:                 "enc_aprendizaje_asociativo"
        case .modificarAsociacionesNoDeseadas:      "enc_modificar_asociaciones_no_deseadas"
        
        //Pensamientos & Sentimientos
        case .queEsUnPensamiento:                   "enc_que_es_un_pensamiento"
        case .pensamientosSentimientosSistemaInmune:"enc_pensamientos_emociones_sistemainmune"
        case .sentimientoComoFuerzaCreadora:        "enc_sentimiento_como_fuerzacreativa"
        case .efectosSentimientosNegativos:         "enc_efecto_sentimie_negativos"
          
            
            
        //Hábitos:
        case .neurocienciaDeLosHabitos:             "enc_neurociencia_habitos"
        case .habitosYAhorroDeEnergia:              "enc_habitos_y_ahorroenergia_cerebral"
        case .romperUnHabito:                       "enc_romper_un_habito"
        case .cuantoTardaEnDebilitarseUnHábito:     "enc_cuanto_tarda_habito_debilitarse"
        case .recaerNoInterrumpeElProgreso:         "enc_recaer_no_interrumpe_progreso"
        case .utilizarRecaidaATuFavor:              "enc_utilizar_recaida_a_tu_favor"
        case .protocoloAntiRecaída:                 "enc_protocolo_antirecaida"
        case .señalConsolidacionHabito:             "enc_señales_consolidacion_habito"
        case .listadoDeHabitosSaludables:           "enc_listado_habitos_saludables"
            
        //Epigenética
        case .epigeneticaSegunVariosAutores:        "enc_epigenetica_varios_autores"
        case .epigeneticaYNeurociencia:             "enc_epigenetica_y_neurociencia"
        case .nevilleYepigenetica:                  "enc_neville_y_epigenetica"
        case .joeDispensaYEpigenetica:              "enc_joedispensa_y_epigenetica"
            
        //Memoria
        case .queEsLaMemoria:                       "enc_que_es_la_memoria"
        case .memoriaSemantica:                     "enc_memoria_semantica"
        case .memoriaEpisodica:                     "enc_memoria_episodica"
        case .memoriaProcedimental:                 "enc_memoria_procedimental"
            
        }
         
        
    }
}


//Categorias de Temas

extension EnciclopediaTemas {
    
    static var temasGenerales: [EnciclopediaTemas] {
        return [
            .atencionFocalizada,
            .atencionFocalizadaPractica,
            .apredizajeAsociativo,
            .coherenciaCardioCerebral,
            .hormonasStress,
            .meditación,
            .menteUniversal,
            .menteConcienteYSubconciente,
            .conciencia,
            .tiempo,
            .entrelazamientoCuanticoNeurociencia,
            .enfermedad,
            .meditacionYExpresionGenica,
            .patronesSinapticosHeredados,
            .patronesConductaHeredados,
            .modificarAsociacionesNoDeseadas
        ]
    }
    
    //Temas sobre Pensamientos & Sentimientos
    static var pensamientoYSentimientos : [EnciclopediaTemas]{
        return [
            .queEsUnPensamiento,
            .efectosSentimientosNegativos,
            .sentimientoComoFuerzaCreadora,
            .pensamientosSentimientosSistemaInmune,
            .sentimientoComoFuerzaCreadora
        ]
    }
    
    //Temas sobre Hábitos
    static var habitos: [EnciclopediaTemas] {
            return [
                .neurocienciaDeLosHabitos,
                .habitosYAhorroDeEnergia,
                .romperUnHabito,
                .cuantoTardaEnDebilitarseUnHábito,
                .recaerNoInterrumpeElProgreso,
                .utilizarRecaidaATuFavor,
                .protocoloAntiRecaída,
                .señalConsolidacionHabito,
                .listadoDeHabitosSaludables
                
            ]
        }
    
    //Temas Epigenética
    static var epigenetica: [EnciclopediaTemas] {
        return [
            .epigeneticaYNeurociencia,
            .epigeneticaSegunVariosAutores,
            .nevilleYepigenetica,
            .joeDispensaYEpigenetica
            
            
        ]
    }
       
    //Temas Memoria
    static var memoria: [EnciclopediaTemas] {
        return [
            .queEsLaMemoria,
            .memoriaSemantica,
            .memoriaEpisodica,
            .memoriaProcedimental
            
            
        ]
    }
    
        
    
    
}
