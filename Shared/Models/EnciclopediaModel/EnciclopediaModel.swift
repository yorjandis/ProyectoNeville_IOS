//
//  EciclopediaModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 22/1/26.
//

import Foundation



enum EnciclopediaTemas: String, CaseIterable, Hashable {
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
    
    //Dopamina:
    case queEsLaDopamina                           = "Qué es la Dopamina"
    case protocoloDopaminergico                    = "Protocolo Dopaminérgico Diario"
    case protocoloAntiAdiccionDigital              = "Protocolo Anti-Adicciones Digitales"
    case dopaminaYProcrastinacion                  = "Dopamina y Procrastinación"
    case dopaminaVersusSerotonina                  = "Dopamina vs Serotonina"
    
    //Serotonina
    case queEsLaSerotonina                        = "Qué es la Serotonina"
    case serotoninaYAnsiedad                      = "Serotonina y Ansiedad"
    case rutinaDiariaProSerotonina                = "Rutina Diaria Pro Serotonina"
    
    
    //Ansiedad:
    case queEsLaAnsiedad                          = "Qué es la Ansiedad"
    case protocoloAntiAnsiedad                    = "Protocolo Anti-Ansiedad"
    case ansiedadVersusStressCronico              = "Ansiedad vs Stress Crónico"
    
    //Emociones:
    case queSonLasEmociones                       = "Qué son las Emociones"
    case almacenamientoEmociones                  = "Almacenamiento de Emociones"
    case componentesDeUnaEmocion                  = "Componenetes de una Emoción"
    case controlEmocion                           = "Control de una Emoción"
    case interocepcionYEmocion                    = "Interocepción y Emoción"
    case protocoloParaReinterprearEmocion         = "Protocolo para Reinterpretar una Emoción"
    
    //Ritmo Circadiano:
    case ritmoCircadiano                       = "El Ritmo Circadiano"
    case genesRelojPerifericos                 = "Activación de Genes Reloj Periféricos"
    case protocoloNormalizarRitmoCircadiano    = "Protocolo para Normalizar Ritmo Circadiano"
    case protocoloNormalizarRitmoCircadiano2    = "Protocolo para Ritmo Circadiano -> Variante optimizada para rendimiento cognitivo"
    
    //🟢
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
            
        //Dopamina:
        case .queEsLaDopamina:                      "enc_que_es_la_dopamina"
        case .protocoloDopaminergico:               "enc_protocolo_dopaminergico"
        case .protocoloAntiAdiccionDigital:         "enc_protocolo_anti_adicciones_digitales"
        case .dopaminaYProcrastinacion:             "enc_dopamina_y_procrastinacion"
        case .dopaminaVersusSerotonina:             "enc_dopamina_vs_serotonina"
            
        //Serotonina:
        case .queEsLaSerotonina:                    "enc_que_es_la_serotonina"
        case .serotoninaYAnsiedad:                  "enc_serotonina_y_ansiedad"
        case .rutinaDiariaProSerotonina:            "enc_rutina_diario_potenciar_serotonina"
            
        //Ansiedad:
        case .queEsLaAnsiedad:                      "enc_que_es_la_ensiedad"
        case .protocoloAntiAnsiedad:                "enc_protocolo_anti_ansiedad"
        case .ansiedadVersusStressCronico:          "enc_ansiedad_vs_stress_cronico"
            
        //Emociones:
        case .queSonLasEmociones:                   "enc_que_es_una_emocion"
        case .almacenamientoEmociones:              "enc_almacenamiento_emociones"
        case .componentesDeUnaEmocion:              "enc_componentes_de_una_emocion"
        case .controlEmocion:                       "enc_control_emociones"
        case .interocepcionYEmocion:                "enc_interocepcion_y_emocion"
        case .protocoloParaReinterprearEmocion:     "enc_protocolo_practico_reinterpretar_emociones"
           
        //Ritmo Circadiano:
        case .ritmoCircadiano:                      "enc_ritmo_circadiano"
        case .genesRelojPerifericos:                 "enc_genes_reloj_perifericos"
        case .protocoloNormalizarRitmoCircadiano:    "enc_protocolo_normalizar_ritmo_circadiano"
        case .protocoloNormalizarRitmoCircadiano2:    "enc_protocolo_normalizar_ritmo_circadiano_2"
        }
         
        
    }
}


extension EnciclopediaTemas {
    /// Título visible del artículo. El nombre del recurso permanece en español
    /// para conservar las rutas, favoritos y referencias existentes.
    var localizedTitle: String {
        guard AppLanguage.current != .spanish else { return rawValue }

        let translations: [EnciclopediaTemas: (english: String, chinese: String)] = [
            .coherenciaCardioCerebral: ("Cardio-Cerebral Coherence", "心脑一致性"),
            .hormonasStress: ("Stress Hormones", "压力激素"),
            .meditación: ("Meditation", "冥想"),
            .menteUniversal: ("The Universal Mind / Quantum Field / Divine Matrix", "普遍心智／量子场／神圣矩阵"),
            .menteConcienteYSubconciente: ("The Conscious and Subconscious Mind", "意识与潜意识"),
            .conciencia: ("Consciousness", "意识"),
            .tiempo: ("The Concept of Time", "时间概念"),
            .entrelazamientoCuanticoNeurociencia: ("Quantum Entanglement from a Neuroscience Perspective", "从神经科学角度看量子纠缠"),
            .enfermedad: ("Disease", "疾病"),
            .meditacionYExpresionGenica: ("Meditation and Gene Expression", "冥想与基因表达"),
            .patronesSinapticosHeredados: ("Inherited/Preformed Synaptic Patterns", "遗传／预形成的突触模式"),
            .patronesConductaHeredados: ("Inherited Behavioral Patterns", "遗传行为模式"),
            .atencionFocalizada: ("Focused Attention", "专注注意力"),
            .atencionFocalizadaPractica: ("Focused Attention Exercises", "专注注意力练习"),
            .apredizajeAsociativo: ("Associative Learning", "联想学习"),
            .modificarAsociacionesNoDeseadas: ("Modifying Unwanted Associations", "改变不需要的联想"),
            .queEsUnPensamiento: ("What Is a Thought?", "什么是思想？"),
            .efectosSentimientosNegativos: ("Effects of Negative Feelings", "负面情绪的影响"),
            .sentimientoComoFuerzaCreadora: ("Feeling as a Creative Force", "情感作为创造力"),
            .pensamientosSentimientosSistemaInmune: ("Thoughts, Feelings, and the Immune System", "思想、情绪与免疫系统"),
            .neurocienciaDeLosHabitos: ("The Neuroscience of Habits", "习惯的神经科学"),
            .habitosYAhorroDeEnergia: ("Habits and Saving Brain Energy", "习惯与节省大脑能量"),
            .romperUnHabito: ("How to Break a Habit Physiologically", "如何从生理层面打破习惯"),
            .cuantoTardaEnDebilitarseUnHábito: ("How Long Does It Take a Habit to Weaken?", "习惯减弱需要多长时间？"),
            .recaerNoInterrumpeElProgreso: ("Why Relapsing Does Not Interrupt Habit Progress", "为什么复发不会中断习惯的进步？"),
            .utilizarRecaidaATuFavor: ("Using a Relapse to Your Advantage", "将复发转化为优势"),
            .protocoloAntiRecaída: ("Relapse Prevention Protocol", "防复发方案"),
            .señalConsolidacionHabito: ("Signs of Habit Consolidation", "习惯巩固的迹象"),
            .listadoDeHabitosSaludables: ("List of Healthy Habits", "健康习惯清单"),
            .epigeneticaSegunVariosAutores: ("Epigenetics According to Various Authors", "多位作者论述的表观遗传学"),
            .epigeneticaYNeurociencia: ("Epigenetics and Neuroscience", "表观遗传学与神经科学"),
            .nevilleYepigenetica: ("Neville and Epigenetics", "内维尔与表观遗传学"),
            .joeDispensaYEpigenetica: ("Joe Dispenza and Epigenetics", "乔·迪斯潘扎与表观遗传学"),
            .queEsLaMemoria: ("What Is Memory?", "什么是记忆？"),
            .memoriaSemantica: ("Semantic Memory", "语义记忆"),
            .memoriaEpisodica: ("Episodic Memory", "情景记忆"),
            .memoriaProcedimental: ("Procedural Memory", "程序性记忆"),
            .queEsLaDopamina: ("What Is Dopamine?", "什么是多巴胺？"),
            .protocoloDopaminergico: ("Daily Dopaminergic Protocol", "每日多巴胺能方案"),
            .protocoloAntiAdiccionDigital: ("Digital Addiction Prevention Protocol", "数字成瘾预防方案"),
            .dopaminaYProcrastinacion: ("Dopamine and Procrastination", "多巴胺与拖延"),
            .dopaminaVersusSerotonina: ("Dopamine vs. Serotonin", "多巴胺与血清素对比"),
            .queEsLaSerotonina: ("What Is Serotonin?", "什么是血清素？"),
            .serotoninaYAnsiedad: ("Serotonin and Anxiety", "血清素与焦虑"),
            .rutinaDiariaProSerotonina: ("Daily Serotonin-Boosting Routine", "提升血清素的日常作息"),
            .queEsLaAnsiedad: ("What Is Anxiety?", "什么是焦虑？"),
            .protocoloAntiAnsiedad: ("Anti-Anxiety Protocol", "抗焦虑方案"),
            .ansiedadVersusStressCronico: ("Anxiety vs. Chronic Stress", "焦虑与慢性压力对比"),
            .queSonLasEmociones: ("What Are Emotions?", "什么是情绪？"),
            .almacenamientoEmociones: ("Emotional Storage", "情绪储存"),
            .componentesDeUnaEmocion: ("Components of an Emotion", "情绪的组成部分"),
            .controlEmocion: ("Emotional Regulation", "情绪调节"),
            .interocepcionYEmocion: ("Interoception and Emotion", "内感受与情绪"),
            .protocoloParaReinterprearEmocion: ("Protocol for Reinterpreting an Emotion", "情绪重新诠释方案"),
            .ritmoCircadiano: ("The Circadian Rhythm", "昼夜节律"),
            .genesRelojPerifericos: ("Activation of Peripheral Clock Genes", "外周时钟基因的激活"),
            .protocoloNormalizarRitmoCircadiano: ("Protocol for Normalizing the Circadian Rhythm", "昼夜节律正常化方案"),
            .protocoloNormalizarRitmoCircadiano2: ("Protocol for Normalizing the Circadian Rhythm → Optimized Variant for Cognitive Performance", "昼夜节律正常化方案 → 认知表现优化版")
        ]

        guard let translation = translations[self] else { return rawValue }
        return AppLanguage.current == .english ? translation.english : translation.chinese
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
    static var temasPensamientoYSentimientos : [EnciclopediaTemas]{
        return [
            .queEsUnPensamiento,
            .efectosSentimientosNegativos,
            .sentimientoComoFuerzaCreadora,
            .pensamientosSentimientosSistemaInmune,
        ]
    }
    
    //Temas sobre Hábitos
    static var temasHabitos: [EnciclopediaTemas] {
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
    static var temasEpigenetica: [EnciclopediaTemas] {
        return [
            .epigeneticaYNeurociencia,
            .epigeneticaSegunVariosAutores,
            .nevilleYepigenetica,
            .joeDispensaYEpigenetica
            
            
        ]
    }
       
    //Temas Memoria
    static var temasMemoria: [EnciclopediaTemas] {
        return [
            .queEsLaMemoria,
            .memoriaSemantica,
            .memoriaEpisodica,
            .memoriaProcedimental
            
            
        ]
    }
    
    //Temas Dopamina:
    static var temasDopamina: [EnciclopediaTemas] {
        return [
            .queEsLaDopamina,
            .dopaminaYProcrastinacion,
            .dopaminaVersusSerotonina,
            .protocoloDopaminergico,
            .protocoloAntiAdiccionDigital
            
            
        ]
    }
    
    //Temas Serotonina:
    static var temasSerotonina: [EnciclopediaTemas] {
        return [
            .queEsLaSerotonina,
            .serotoninaYAnsiedad,
            .rutinaDiariaProSerotonina
            
            
        ]
    }
        
    //Temas Ansiedad:
    static var temasAnsiedad: [EnciclopediaTemas] {
        return [
            .queEsLaAnsiedad,
            .ansiedadVersusStressCronico,
            .protocoloAntiAnsiedad
            
            
        ]
    }
    
    //Temas Emociones:
    static var temasEmociones: [EnciclopediaTemas] {
        return [
            .queSonLasEmociones,
            .almacenamientoEmociones,
            .componentesDeUnaEmocion,
            .interocepcionYEmocion,
            .controlEmocion,
            .protocoloParaReinterprearEmocion  
            
            
        ]
    }
    
    //Temas Ritmo Circadiano
    static var temasRitmoCircadianos: [EnciclopediaTemas] {
        return [
            .ritmoCircadiano,
            .genesRelojPerifericos,
            .protocoloNormalizarRitmoCircadiano,
            .protocoloNormalizarRitmoCircadiano2
        ]
    }
    
}
