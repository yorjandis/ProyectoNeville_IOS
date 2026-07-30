import Foundation

struct TransformationProtocolDayPlan: Identifiable, Equatable, Sendable {
    let number: Int
    let title: String
    let phase: String
    let objective: String
    let exercise: String
    let prompts: [String]
    let action: String
    let principle: String?

    var id: Int { number }
}

struct TransformationProtocolExample: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let patternName: String
    let trigger: String
    let automaticThought: String
    let emotion: String
    let oldBehavior: String
    let consequence: String
    let alternativeBehavior: String
    let toleratedEmotion: String
    let identity: String
}

struct TransformationProtocolExampleSelection: Identifiable, Equatable, Sendable {
    let id = UUID()
    let example: TransformationProtocolExample
}

enum TransformationProtocolCatalog {
    static let examples: [TransformationProtocolExample] = [
        .init(
            id: 1,
            title: "Responder mejor a una crítica",
            patternName: "Reacción defensiva",
            trigger: "recibo una crítica o una corrección sobre mi trabajo",
            automaticThought: "no valoran mi esfuerzo y tengo que defenderme",
            emotion: "tensión en la mandíbula, vergüenza e irritación",
            oldBehavior: "interrumpo, justifico mis decisiones o respondo con dureza",
            consequence: "la conversación se vuelve tensa y pierdo información que podría ayudarme",
            alternativeBehavior: "respiraré lentamente, escucharé hasta el final y haré una pregunta antes de responder",
            toleratedEmotion: "incomodidad y vulnerabilidad",
            identity: "escucha con serenidad y utiliza el feedback para aprender"
        ),
        .init(
            id: 2,
            title: "Comenzar una tarea difícil",
            patternName: "Procrastinación por incomodidad",
            trigger: "tengo que comenzar una tarea importante, incierta o exigente",
            automaticThought: "necesito sentirme preparado y tener más tiempo para hacerlo bien",
            emotion: "pesadez, inquietud y resistencia",
            oldBehavior: "abro el correo, ordeno cosas menores o pospongo el inicio",
            consequence: "acumulo presión, reduzco la calidad del trabajo y refuerzo la evitación",
            alternativeBehavior: "cerraré las distracciones y trabajaré diez minutos en el primer paso concreto",
            toleratedEmotion: "pereza, duda y falta de motivación",
            identity: "empieza con claridad aunque todavía no se sienta preparado"
        ),
        .init(
            id: 3,
            title: "Reducir la revisión del teléfono",
            patternName: "Revisión compulsiva del teléfono",
            trigger: "aparece una pausa, aburrimiento o una notificación",
            automaticThought: "solo miraré un momento por si hay algo importante",
            emotion: "inquietud en las manos y deseo de estimulación",
            oldBehavior: "desbloqueo el teléfono y salto entre aplicaciones sin una intención definida",
            consequence: "pierdo atención, alargo las pausas y termino más disperso",
            alternativeBehavior: "dejaré el teléfono fuera de alcance, haré tres respiraciones y volveré a la actividad elegida",
            toleratedEmotion: "aburrimiento y curiosidad",
            identity: "protege deliberadamente su atención"
        ),
        .init(
            id: 4,
            title: "Regular la comida por estrés",
            patternName: "Comer impulsivamente bajo estrés",
            trigger: "termino una situación exigente o siento sobrecarga emocional",
            automaticThought: "necesito comer algo ahora para sentirme mejor",
            emotion: "vacío en el abdomen, tensión y urgencia",
            oldBehavior: "como rápidamente sin comprobar si tengo hambre física",
            consequence: "obtengo alivio breve y después siento pesadez, culpa y menor confianza",
            alternativeBehavior: "beberé agua, caminaré cinco minutos y comprobaré de nuevo mi hambre antes de decidir",
            toleratedEmotion: "ansiedad y deseo",
            identity: "atiende sus necesidades sin reaccionar automáticamente"
        ),
        .init(
            id: 5,
            title: "Afrontar una conversación incómoda",
            patternName: "Evitación de conversaciones",
            trigger: "necesito expresar un límite, desacuerdo o petición importante",
            automaticThought: "si lo digo crearé un conflicto o decepcionaré a la otra persona",
            emotion: "presión en el pecho, miedo y anticipación",
            oldBehavior: "pospongo la conversación, cedo o comunico de forma indirecta",
            consequence: "acumulo resentimiento y el problema continúa sin una solución clara",
            alternativeBehavior: "prepararé una petición concreta y propondré un momento para hablar con calma",
            toleratedEmotion: "miedo al conflicto y posible desaprobación",
            identity: "comunica sus límites con honestidad y respeto"
        ),
        .init(
            id: 6,
            title: "Mantener una rutina sin resultados inmediatos",
            patternName: "Abandono prematuro",
            trigger: "no observo resultados rápidos o pierdo un día de mi rutina",
            automaticThought: "esto no está funcionando y ya he estropeado el progreso",
            emotion: "desánimo, impaciencia y frustración",
            oldBehavior: "abandono varios días o busco un plan nuevo",
            consequence: "impido la continuidad necesaria y refuerzo la idea de que no soy constante",
            alternativeBehavior: "realizaré hoy la versión mínima y revisaré el proceso al final de la semana",
            toleratedEmotion: "desánimo e incertidumbre",
            identity: "prioriza la constancia y vuelve al proceso después de un desliz"
        )
    ]

    static let days: [TransformationProtocolDayPlan] = [
        .init(
            number: 1,
            title: "Contrato de transformación",
            phase: "Fase I · Observar y cartografiar",
            objective: "Definir con precisión qué cambiarás y por qué.",
            exercise: "Escribe tu contrato. Durante 21 días no necesitas demostrar que ya has cambiado: observa, practica y recopila evidencias mediante tus acciones.",
            prompts: [
                "¿Desde cuándo observas el patrón y en qué situaciones aparece?",
                "¿Qué costes produce y qué beneficio oculto proporciona?",
                "¿Qué ocurrirá dentro de un año si no cambia?",
                "¿Qué posibilidades aparecerán al responder de otra forma?"
            ],
            action: "Comparte el compromiso con alguien de confianza o déjalo visible.",
            principle: "Un patrón puede aliviar, proteger o dar control a corto plazo. Reconocer esa recompensa permite cambiarlo."
        ),
        .init(
            number: 2,
            title: "Mapa de desencadenantes",
            phase: "Fase I · Observar y cartografiar",
            objective: "Identificar qué inicia el patrón.",
            exercise: "Clasifica tus desencadenantes en externos, internos, cognitivos, emocionales y contextuales.",
            prompts: [
                "Personas, palabras, lugares, horarios o dispositivos.",
                "Cansancio, hambre, dolor, aburrimiento, inseguridad o soledad.",
                "Recuerdos, comparaciones, expectativas o interpretaciones.",
                "Miedo, frustración, vergüenza, ira o injusticia.",
                "Falta de sueño, prisas, sobrecarga, alcohol o falta de planificación."
            ],
            action: "Registra tres señales tempranas, aunque el patrón no llegue a completarse.",
            principle: nil
        ),
        .init(
            number: 3,
            title: "Lenguaje del antiguo yo",
            phase: "Fase I · Observar y cartografiar",
            objective: "Detectar las frases mentales que sostienen la conducta.",
            exercise: "Para cada frase automática distingue hechos de interpretaciones y crea una alternativa precisa, creíble y operativa.",
            prompts: [
                "¿Es un hecho o una interpretación?",
                "¿Qué emoción produce?",
                "¿Qué conducta favorece?",
                "¿Qué alternativa sería más precisa?"
            ],
            action: "Cuando aparezca una frase automática, di: «Estoy teniendo el pensamiento de que…».",
            principle: "Observar un pensamiento reduce la identificación con su contenido."
        ),
        .init(
            number: 4,
            title: "Memoria corporal",
            phase: "Fase I · Observar y cartografiar",
            objective: "Reconocer cómo comienza el patrón en el cuerpo.",
            exercise: "Recuerda tres episodios y localiza el primer cambio corporal, la tensión, la respiración, la postura, la temperatura y el movimiento.",
            prompts: [
                "¿Cuál es la primera señal física?",
                "¿Dónde aparece la máxima tensión?",
                "¿Cómo cambian respiración, postura y velocidad del habla?",
                "Completa: «Mi patrón comienza con…»."
            ],
            action: "Haz cinco exploraciones corporales breves a lo largo del día.",
            principle: "Practica la detección antes de estar alterado."
        ),
        .init(
            number: 5,
            title: "Cadena de consecuencias",
            phase: "Fase I · Observar y cartografiar",
            objective: "Observar el coste completo del comportamiento.",
            exercise: "Traza la cadena antigua y después una alternativa: desencadenante → pensamiento → emoción → impulso → conducta → consecuencias → identidad reforzada.",
            prompts: [
                "¿Qué alivio inmediato ofrece la conducta antigua?",
                "¿Qué coste aparece a medio plazo?",
                "¿Qué identidad refuerza?",
                "¿Cómo sería la cadena con la respuesta alternativa?"
            ],
            action: "Antes de actuar, imagina durante diez segundos las consecuencias de segundo orden.",
            principle: nil
        ),
        .init(
            number: 6,
            title: "Diseño del entorno",
            phase: "Fase I · Observar y cartografiar",
            objective: "Reducir la dependencia de la fuerza de voluntad.",
            exercise: "Clasifica el entorno según favorezca el patrón antiguo, el nuevo o sea neutral. Realiza tres cambios concretos.",
            prompts: [
                "¿Qué señal hace demasiado fácil la conducta antigua?",
                "¿Qué barrera física o tecnológica puedes añadir?",
                "¿Qué puedes dejar preparado para facilitar la conducta nueva?"
            ],
            action: "Aplica hoy una barrera contra el patrón antiguo.",
            principle: "Haz más difícil la conducta antigua y más sencilla la nueva."
        ),
        .init(
            number: 7,
            title: "Primera revisión",
            phase: "Fase I · Observar y cartografiar",
            objective: "Convertir las observaciones en una hipótesis de trabajo.",
            exercise: "Revisa desencadenante, señal corporal, pensamiento, emoción evitada, recompensa, vulnerabilidades y eficacia del entorno.",
            prompts: [
                "¿Cuál fue el desencadenante más frecuente?",
                "¿En qué momento podías haber intervenido antes?",
                "¿Cuántas pausas y respuestas alternativas realizaste?",
                "¿Cuál fue la intensidad y recuperación media?"
            ],
            action: "Resume tu hipótesis del patrón en tres líneas.",
            principle: "Ver con más claridad el automatismo ya es progreso."
        ),
        .init(
            number: 8,
            title: "Construcción de la pausa",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Insertar espacio entre impulso y acción.",
            exercise: "Practica P.A.R.A. cinco veces en calma: percibe la señal, aplaza, regula y actúa según el protocolo.",
            prompts: [
                "¿Qué palabra interna señalará la pausa?",
                "¿Qué parte del cuerpo relajarás primero?",
                "¿Qué señal física discreta usarás?",
                "¿Cuál es la conducta alternativa exacta?"
            ],
            action: "Usa una señal física de pausa al menos una vez.",
            principle: "No esperes a estar activado para entrenar la pausa."
        ),
        .init(
            number: 9,
            title: "Tolerancia a la emoción",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Sentir una emoción incómoda sin obedecerla.",
            exercise: "Durante 90 segundos observa ubicación, tamaño, intensidad, temperatura, presión y movimiento sin elaborar la historia mental.",
            prompts: [
                "¿Dónde está la emoción?",
                "¿Cómo cambia durante 90 segundos?",
                "¿Qué impulso puedes dejar pasar sin ejecutarlo?"
            ],
            action: "Permanece deliberadamente con una incomodidad leve sin escapar.",
            principle: "La emoción puede estar presente sin convertirse en conducta."
        ),
        .init(
            number: 10,
            title: "Pensamiento operativo",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Sustituir interpretaciones absolutas por instrucciones útiles.",
            exercise: "Crea una respuesta que sea creíble, precisa y favorezca la conducta elegida.",
            prompts: [
                "¿Qué parte de tu pensamiento automático es absoluta?",
                "¿Qué sí controlas en esta situación?",
                "¿Qué frase te devuelve al proceso?"
            ],
            action: "Coloca una frase operativa en un lugar visible.",
            principle: "No necesitas creer una afirmación grandiosa; necesitas una instrucción practicable."
        ),
        .init(
            number: 11,
            title: "Conducta incompatible",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Elegir una acción que dificulte continuar el patrón antiguo.",
            exercise: "Completa: «Cuando detecte…, realizaré inmediatamente… durante… minutos».",
            prompts: [
                "¿Qué acción no puede coexistir fácilmente con tu patrón?",
                "¿Cuánto tiempo necesitas mantenerla?",
                "¿Cómo la iniciarás sin negociar contigo?"
            ],
            action: "Ejecuta la conducta incompatible ante un desencadenante leve.",
            principle: nil
        ),
        .init(
            number: 12,
            title: "Exposición gradual",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Practicar ante una versión controlada del desencadenante.",
            exercise: "Crea una escala de intensidad del 1 al 10 y practica hoy con una situación de nivel 3 o 4.",
            prompts: [
                "¿Qué intensidad anticipabas y cuál fue la real?",
                "¿Qué respuesta utilizaste?",
                "¿Cuánto tardaste en recuperarte?",
                "¿Qué aprendiste?"
            ],
            action: "Realiza una exposición manejable y registra el proceso.",
            principle: "El objetivo no es estar totalmente tranquilo, sino ejecutar el protocolo."
        ),
        .init(
            number: 13,
            title: "R.E.P.A.R.A. un desliz",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Evitar que un error se convierta en una cadena.",
            exercise: "Reconoce, evita el juicio global, para la cadena, analiza, repara y ajusta.",
            prompts: [
                "¿Cuál es tu desliz más probable?",
                "¿Cómo detendrás las decisiones posteriores?",
                "¿Qué puedes reparar?",
                "¿Qué barrera añadirás para la próxima vez?"
            ],
            action: "Escribe anticipadamente tu plan de reparación.",
            principle: "Una conducta que quieres modificar no define tu identidad."
        ),
        .init(
            number: 14,
            title: "Segunda revisión",
            phase: "Fase II · Interrumpir y sustituir",
            objective: "Comprobar si la respuesta automática pierde velocidad.",
            exercise: "Visualiza un episodio leve, uno moderado y uno intenso. En cada uno practica señal, pausa, emoción, frase operativa y respuesta alternativa.",
            prompts: [
                "¿Detectas antes las señales?",
                "¿Qué regulación funciona mejor?",
                "¿Qué desencadenantes aún te superan?",
                "¿Estás practicando o solo reflexionando?"
            ],
            action: "Ensaya los tres niveles durante cinco minutos.",
            principle: "Una pequeña separación entre impulso y respuesta ya es éxito."
        ),
        .init(
            number: 15,
            title: "Identidad basada en conducta",
            phase: "Fase III · Construir y consolidar",
            objective: "Definir quién quieres ser mediante acciones concretas.",
            exercise: "Completa «Estoy entrenando para convertirme en una persona que…» y tradúcelo en cinco conductas observables.",
            prompts: [
                "¿Qué identidad de proceso quieres entrenar?",
                "¿Qué cinco acciones la demuestran?",
                "¿Cuál puedes realizar hoy?"
            ],
            action: "Produce una evidencia pequeña de esa identidad.",
            principle: "Prefiere identidades como paciente, íntegro, constante o responsable frente a resultados externos."
        ),
        .init(
            number: 16,
            title: "Acumulación de evidencias",
            phase: "Fase III · Construir y consolidar",
            objective: "Reforzar la identidad mediante pruebas reales.",
            exercise: "Registra evidencias conductuales: pausas, límites respetados, acciones iniciadas, escucha, tolerancia o recuperación.",
            prompts: [
                "¿Qué hiciste aunque apareció incomodidad?",
                "¿Qué límite respetaste?",
                "¿Cómo regresaste al proceso tras un error?"
            ],
            action: "Busca tres evidencias pequeñas, no una demostración heroica.",
            principle: "Registra lo que hiciste, no solo cómo te sentiste."
        ),
        .init(
            number: 17,
            title: "Estrés controlado",
            phase: "Fase III · Construir y consolidar",
            objective: "Mantener la respuesta nueva con presión moderada.",
            exercise: "Antes de una dificultad manejable, prepara desencadenante, señal, pensamiento, pausa, conducta alternativa y criterio de detención.",
            prompts: [
                "¿Qué desencadenante esperas?",
                "¿Cuál será tu criterio para detenerte?",
                "Puntúa por separado resultado externo y calidad del proceso."
            ],
            action: "Realiza una prueba moderada y evalúa la ejecución.",
            principle: "Un mal resultado externo puede coexistir con un proceso excelente."
        ),
        .init(
            number: 18,
            title: "Entorno social y límites",
            phase: "Fase III · Construir y consolidar",
            objective: "Alinear relaciones y entorno con la nueva conducta.",
            exercise: "Identifica apoyos, dinámicas que refuerzan el patrón, conversaciones evitadas y límites necesarios.",
            prompts: [
                "¿Qué persona puede ofrecer apoyo específico?",
                "¿Qué dinámica necesitas abandonar?",
                "¿Qué petición clara necesitas hacer?"
            ],
            action: "Comunica un límite o una petición concreta.",
            principle: "«Cuando ocurre…, me resulta difícil… A partir de ahora voy a… Te pido que…»"
        ),
        .init(
            number: 19,
            title: "Visualización de obstáculos",
            phase: "Fase III · Construir y consolidar",
            objective: "Ensayar dificultades, no solo el éxito.",
            exercise: "Divide el ensayo en deseo, resultado, obstáculo interno y plan de respuesta.",
            prompts: [
                "¿Qué identidad construyes?",
                "¿Qué mejorará al actuar así?",
                "¿Qué pensamiento, emoción o impulso puede detenerte?",
                "¿Qué harás exactamente cuando aparezca?"
            ],
            action: "Ensaya el obstáculo tres veces con la respuesta nueva.",
            principle: nil
        ),
        .init(
            number: 20,
            title: "Simulación integral",
            phase: "Fase III · Construir y consolidar",
            objective: "Ejecutar el protocolo completo como una situación real.",
            exercise: "Simula contexto, señal, pensamiento, emoción, impulso, pausa, regulación, frase, conducta, posible desliz, reparación y cierre.",
            prompts: [
                "Incluye dudas y una emoción que no desaparece.",
                "Incluye un resultado incierto.",
                "Incluye el deseo de volver al patrón y la reparación."
            ],
            action: "Realiza una versión realista o una acción que te acerque a ella.",
            principle: "Mantén el proceso aunque la experiencia sea imperfecta."
        ),
        .init(
            number: 21,
            title: "Evaluación y consolidación",
            phase: "Fase III · Construir y consolidar",
            objective: "Medir el cambio y convertirlo en un sistema sostenible.",
            exercise: "Compara frecuencia, intensidad, detección, pausas, respuestas alternativas, recuperación, consecuencias y confianza entre el inicio y hoy.",
            prompts: [
                "¿Qué descubriste y qué respuesta funciona mejor?",
                "¿Qué evidencia demuestra el cambio?",
                "¿Qué parte necesita más entrenamiento?",
                "¿Cómo responderás a la recaída más probable?",
                "¿Qué conducta mantendrás durante 30 días?"
            ],
            action: "Conserva visible el protocolo y agenda cuatro revisiones semanales.",
            principle: "La nueva identidad se establece al acumular experiencias de respuesta diferente ante el mismo desencadenante."
        )
    ]

    static let morningRoutine: [(title: String, minutes: Int, detail: String)] = [
        ("Regulación fisiológica", 3, "Inhala 4 segundos, exhala 6. Relaja mandíbula, hombros y manos."),
        ("Observación corporal", 4, "Recorre rostro, cuello, pecho, abdomen, espalda, brazos y piernas."),
        ("Reconocer el patrón", 5, "Observa señal, pensamiento, emoción e impulso sin convertirlos en identidad."),
        ("Interrupción y ensayo", 7, "Imagina el obstáculo, reconoce la urgencia y ejecuta tu respuesta alternativa."),
        ("Compromiso del día", 2, "Define una acción observable que demostrará hoy tu nueva identidad.")
    ]

    static let minimumRoutine: [(title: String, minutes: Int, detail: String)] = [
        ("Respiración lenta", 2, "Reduce la activación con una exhalación más larga."),
        ("Observación corporal", 2, "Localiza tensión e inquietud sin intentar eliminarlas."),
        ("Reconocer el patrón", 2, "Nombra el patrón y su impulso."),
        ("Ensayo mental", 2, "Practica la pausa y la respuesta alternativa."),
        ("Acción del día", 2, "Escribe una conducta observable.")
    ]
}
