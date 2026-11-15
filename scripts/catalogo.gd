class_name Catalogo
extends RefCounted
## Todo el contenido histórico del juego. Para corregir un texto o agregar una
## pieza solo hay que tocar este archivo. Las fuentes están en docs/FUENTES.md.
##
## "imagen": si existe res://arte/<id>.jpg (o .png), el juego la usa en el cuadro y
## en el bolso. Si no, dibuja un cuadro provisional con los colores de "paleta".
## "museo": de qué colección viene (sección de la agenda). Ver MUSEOS.
## "modelo": cómo se arma en 3D una pieza que no es cuadro (ver obra.gd).
## "fija": siempre está en la agenda. "sala_fija": no se reparte al azar.
## "tela": se cuelga sin marco, como una bandera.

## Secciones de la agenda, en este orden.
const MUSEOS: Array[Dictionary] = [
	{"id": "especial", "nombre": "Encargo principal", "placa": "Préstamo especial del MAMBO"},
	{"id": "urrutia", "nombre": "Miguel Urrutia (en préstamo)", "placa": "En préstamo · Museo de Arte Miguel Urrutia"},
	{"id": "nacional", "nombre": "Museo Nacional", "placa": ""},
	{"id": "oro", "nombre": "Museo del Oro (en préstamo)", "placa": "En préstamo · Museo del Oro"},
]

const OBRAS: Array[Dictionary] = [
	{
		"id": "violencia", "museo": "urrutia", "titulo": "Violencia", "autor": "Alejandro Obregón", "anio": "1962",
		"tipo": "pintura", "tam": Vector2(2.4, 1.3),
		"paleta": ["#3b3f45", "#6d7278", "#1d1f22"],
		"razon": "Ese cuadro le recuerda a la gente lo que pasó. Mejor que se les olvide.",
		"texto": "Primer premio de pintura en el Salón Nacional de Artistas de 1962. Una mujer mutilada y encinta, cuyo rostro, seno y vientre forman un paisaje de montañas grises. Obregón no muestra a los asesinos: solo a la víctima de la violencia bipartidista que vivió Colombia desde finales de los años cuarenta.",
	},
	{
		"id": "decoracion", "museo": "urrutia", "titulo": "Decoración de interiores", "autor": "Beatriz González", "anio": "1981",
		"tipo": "pintura", "tam": Vector2(2.2, 1.6),
		"paleta": ["#2f7d5b", "#e8d9a0", "#b5472f"],
		"razon": "Una cortina burlándose de un presidente. Con el poder no se juega.",
		"texto": "Serigrafía sobre tela que repite, como un estampado de cortina, una foto de prensa del presidente Julio César Turbay cantando en una fiesta. La artista convirtió la imagen del poder en un objeto de decoración, en plena época de estado de sitio.",
	},
	{
		"id": "retratos_mudos", "museo": "urrutia", "titulo": "Retratos mudos", "autor": "Beatriz González", "anio": "",
		"tipo": "pintura", "tam": Vector2(1.5, 1.5),
		"paleta": ["#c9a227", "#5a3e2b", "#efe6c8"],
		"razon": "Esas caras ya no tienen voz. Que tampoco tengan pared.",
		"texto": "Beatriz González tomó imágenes de la prensa y la historia colombiana para pintar lo que el país prefiere no mirar. Figura entre las obras destacadas en la selección de cien tesoros del museo.",
	},
	{
		"id": "mandolina", "museo": "urrutia", "titulo": "Mandolina", "autor": "Fernando Botero", "anio": "1957",
		"tipo": "pintura", "tam": Vector2(1.5, 1.2),
		"paleta": ["#d98b2b", "#7a3b1d", "#f0d9a8"],
		"razon": "Con ese cuadro empezó todo. Sin el primero, los demás no significan nada.",
		"texto": "Llegó en 1957 con la donación de la V Reunión de Bancos Centrales del Continente Americano, en el origen de la colección de arte del Banco de la República. Quitarla es arrancar la primera página de la historia del museo.",
	},
	{
		"id": "monjas", "museo": "urrutia", "titulo": "Monjas muertas", "autor": "Atribuido a Victorino García Romero", "anio": "ca. 1809",
		"tipo": "pintura", "tam": Vector2(1.1, 1.5),
		"paleta": ["#1c1a1a", "#b9a98f", "#6b1f1f"],
		"razon": "Doscientos años mirando desde esa pared. Ya estuvo bueno.",
		"texto": "Parte de un conjunto de doce pinturas de monjas muertas de hacia 1809, atribuidas a Victorino García Romero, con sala especial en el museo. Es memoria de la vida religiosa y de la muerte en el Nuevo Reino, justo antes de la Independencia.",
	},
	{
		"id": "chatarra", "museo": "urrutia", "titulo": "Chatarra", "autor": "Feliza Bursztyn", "anio": "",
		"tipo": "escultura", "tam": Vector2(1.0, 1.4),
		"paleta": ["#5c5f63", "#8a6a4f"],
		"razon": "A ella ya la sacaron del país una vez. Terminemos el trabajo.",
		"texto": "Bursztyn fue pionera de la escultura en chatarra en Colombia desde 1961. En 1981, bajo el estado de sitio, los militares la detuvieron e interrogaron por supuestos vínculos con el M-19 que nunca se probaron. Se asiló en la embajada de México y murió en París en enero de 1982, a los 48 años.",
	},
	{
		"id": "negret", "museo": "urrutia", "titulo": "Aparato mágico", "autor": "Édgar Negret", "anio": "",
		"tipo": "escultura", "tam": Vector2(0.9, 1.2),
		"paleta": ["#c23a2b", "#20262e"],
		"razon": "Parece una máquina y no sirve para nada. Peor: pone a pensar.",
		"texto": "Negret, nacido en Popayán, fue uno de los maestros de la escultura moderna colombiana. Sus Aparatos mágicos, hechos en metal con tornillos y tuercas a la vista, unen la técnica industrial con el misterio. Tiene lugar en la sala de maestros del siglo XX.",
	},
	{
		"id": "lechuga", "museo": "urrutia", "titulo": "La Lechuga", "autor": "José de Galaz", "anio": "1700-1707",
		"tipo": "objeto", "modelo": "custodia", "tam": Vector2(0.45, 0.8),
		"paleta": ["#d4af37", "#1f8a4c"],
		"razon": "La joya de la corona. Esa sí me la trae intacta.",
		"texto": "Custodia de la iglesia de San Ignacio de Bogotá, en oro con 1.485 esmeraldas, además de rubíes, diamantes, perlas y amatistas. Los jesuitas la vendieron al Banco de la República en los años ochenta: las fuentes dan 1985 o 1987. En 2015 salió de Colombia por primera vez para exhibirse en el Prado.",
	},
	# ------------------------------------------------ Encargo principal
	{
		"id": "cuadro_enlace", "museo": "especial", "fija": true, "sala_fija": true,
		"titulo": "Cuadro del MAMBO (PENDIENTE)", "autor": "PENDIENTE", "anio": "",
		"tipo": "pintura", "tam": Vector2(1.2, 1.2),
		"paleta": ["#4b3b2a", "#8f7a55", "#2e4a3f"],
		"razon": "Ese cuadro ha pasado por más museos que usted por colegios. Esta noche se jubila en mi sala.",
		"texto": "Cuadro ficticio que enlaza este juego con el de otro equipo, ambientado en el museo geológico. Pasó por varios museos, entre ellos el MAMBO, cuyas directivas lo prestaron al Museo Nacional por un solo día. Título, autor e historia completa: PENDIENTE.",
	},
	# ------------------------------------------------ Museo Nacional
	# Piezas retiradas por orden del Gobierno el 15 de octubre de 2026 (ver FUENTES.md).
	{
		"id": "afiche_pizarro", "museo": "nacional", "titulo": "Afiche de campaña de Carlos Pizarro", "autor": "Campaña presidencial", "anio": "1990",
		"tipo": "pintura", "tam": Vector2(0.7, 1.0),
		"paleta": ["#f2efe6", "#1f5aa6", "#d1342b"],
		"razon": "El presidente ya lo mandó a bajar y un juececito lo volvió a colgar. Yo no le pido permiso a ningún juez.",
		"texto": "Carlos Pizarro fue el comandante del M-19 que lideró la desmovilización de esa guerrilla. Lo asesinaron el 26 de abril de 1990, en plena campaña presidencial. El 15 de octubre de 2026 el presidente Abelardo de la Espriella ordenó retirar de los espacios públicos lo que considera exaltación del terrorismo y nombró a Pizarro. Un juez ordenó devolver las piezas, que volvieron a las salas a finales de octubre.",
	},
	{
		"id": "afiche_jaramillo", "museo": "nacional", "titulo": "Afiche de campaña de Bernardo Jaramillo Ossa", "autor": "Unión Patriótica", "anio": "1990",
		"tipo": "pintura", "tam": Vector2(0.7, 1.0),
		"paleta": ["#f4e9d0", "#1d7a3e", "#c8232c"],
		"razon": "A ese ya lo callaron en el noventa. Ahora callamos el afiche y quedamos parejos.",
		"texto": "Bernardo Jaramillo Ossa fue candidato presidencial de la Unión Patriótica. Lo asesinaron en Bogotá el 22 de marzo de 1990, en un crimen atribuido a grupos paramilitares en alianza con sectores del Estado. Su afiche fue retirado del museo el 15 de octubre de 2026 y devuelto por orden judicial.",
	},
	{
		"id": "baligrafo", "museo": "nacional", "titulo": "El Balígrafo", "autor": "Firma del Acuerdo de Paz", "anio": "2016",
		"tipo": "objeto", "modelo": "baligrafo", "tam": Vector2(0.6, 0.45),
		"paleta": ["#c9a54a", "#7a4a26"],
		"razon": "Una bala volteada esfero. Yo la quiero de vuelta de bala, como Dios manda.",
		"texto": "Pluma hecha con una bala, con la que se firmó en 2016 el Acuerdo de Paz con las FARC. Lleva grabada la frase: «Las balas escribieron nuestro pasado. La educación, nuestro futuro». Fue retirada del museo el 15 de octubre de 2026 y devuelta por orden judicial.",
	},
	{
		"id": "septima_papeleta", "museo": "nacional", "titulo": "La Séptima Papeleta", "autor": "Movimiento estudiantil", "anio": "1990",
		"tipo": "objeto", "modelo": "documento", "tam": Vector2(0.6, 0.45),
		"paleta": ["#f1ead8", "#e0b52a", "#5a3f9a"],
		"razon": "Unos pelados con un papelito cambiaron la Constitución. Eso no puede volver a pasar, ¿sí me entiende?",
		"texto": "En las elecciones de marzo de 1990, estudiantes promovieron meter una papeleta extra que pedía una Asamblea Nacional Constituyente. De ahí salió la Constitución de 1991. El tarjetón estaba en el muro «De la Constitución de 1991 al Proceso de Paz de 2016» y fue retirado el 15 de octubre de 2026.",
	},
	{
		"id": "bandera_castillo", "museo": "nacional", "titulo": "Bandera del orgullo de Elizabeth Castillo", "autor": "De la activista Elizabeth Castillo", "anio": "",
		"tipo": "pintura", "tela": true, "tam": Vector2(1.5, 0.9),
		"paleta": ["#e40303", "#ff8c00", "#ffed00", "#008026", "#004dff", "#750787"],
		"razon": "Demasiados colores pa' un museo serio. Tráigamela doblada.",
		"texto": "Bandera del orgullo que perteneció a la activista Elizabeth Castillo. Estaba en la sala «Hacer sociedad», junto a otras piezas sobre la historia LGBTI y el movimiento feminista en Colombia. Fue retirada el 15 de octubre de 2026 y devuelta por orden judicial.",
	},
	{
		"id": "ventana_gay", "museo": "nacional", "titulo": "La Ventana Gay, número 2", "autor": "Manuel Antonio Velandia y León Zuleta", "anio": "",
		"tipo": "objeto", "modelo": "documento", "tam": Vector2(0.6, 0.45),
		"paleta": ["#efe4c8", "#3a3a3a", "#b0413e"],
		"razon": "Esa ventana me la cierra, Polo. Con candado.",
		"texto": "Revista del activismo gay hecha por Manuel Antonio Velandia y León Zuleta. Zuleta, activista antioqueño, fue asesinado en 1993. El ejemplar estaba en la sala «Hacer sociedad» y fue retirado el 15 de octubre de 2026.",
	},
	{
		"id": "camiseta_lucho", "museo": "nacional", "titulo": "Camiseta de Lucho Herrera", "autor": "Equipo Café de Colombia", "anio": "",
		"tipo": "objeto", "modelo": "camiseta", "tam": Vector2(0.7, 1.1),
		"paleta": ["#f5f5f2", "#1d3f8f", "#f2c500", "#c8232c"],
		"razon": "¿Qué tiene de terrorista un escarabajo? Ni idea, pero si el Ministerio la bajó, por algo será.",
		"texto": "Luis «Lucho» Herrera fue el primer colombiano en ganar una etapa del Tour de Francia, en 1984, y ganó la Vuelta a España en 1987. Su camiseta estaba entre las piezas retiradas del museo el 15 de octubre de 2026. El Gobierno no explicó por qué.",
	},
	{
		"id": "grabado_rojas", "museo": "nacional", "titulo": "Grabado (título PENDIENTE)", "autor": "Miguel Ángel Rojas", "anio": "",
		"tipo": "pintura", "tam": Vector2(0.75, 1.1),
		"paleta": ["#f2f2f0", "#555555", "#111111"],
		"razon": "Si el Ministerio lo bajó, yo lo desaparezco. Trabajo en equipo.",
		"texto": "Miguel Ángel Rojas es un artista bogotano que, desde finales de los setenta, retrató en su obra el deseo homosexual en la ciudad, en una época en que era perseguido. Algunos de sus grabados estaban entre las piezas retiradas del museo el 15 de octubre de 2026.",
	},
	{
		"id": "policarpa", "museo": "nacional", "titulo": "Policarpa Salavarrieta marcha al suplicio", "autor": "Anónimo", "anio": "1825",
		"tipo": "pintura", "tam": Vector2(1.25, 1.0),
		"paleta": ["#3c5a8a", "#e8dcc0", "#2a2420"],
		"razon": "Una mujer que conspiró contra el gobierno de turno. Pésimo ejemplo pa' la juventud.",
		"texto": "Pintura anónima de 1825. Su inscripción dice que Policarpa Salavarrieta fue sacrificada por los españoles en esa plaza el 14 de noviembre de 1817, y pide que su memoria sea eterna. La espía de la Independencia, convertida en mártir pocos años después de su muerte.",
	},
	# ------------------------------------------------ Museo del Oro
	{
		"id": "poporo_quimbaya", "museo": "oro", "fija": true, "titulo": "Poporo Quimbaya", "autor": "Orfebrería quimbaya", "anio": "",
		"tipo": "objeto", "modelo": "poporo", "tam": Vector2(0.6, 0.6),
		"paleta": ["#d4a52c", "#8a6414"],
		"razon": "El Banco lo compró en el 39 pa' que no lo fundieran. Yo lo compro pa' lo mismo, pero al revés.",
		"texto": "Recipiente de oro en el que se guardaba la cal que se masca con hoja de coca. El Banco de la República lo compró en 1939 para salvarlo de la fundición, y se volvió el símbolo del Museo del Oro. Esta noche está en préstamo en el Nacional.",
	},
]

## Cuadros de relleno: decoran las salas pero nunca están en la agenda.
const RELLENO: Array[Dictionary] = [
	{"id": "relleno_grau", "titulo": "Obra de la colección", "autor": "Enrique Grau", "anio": "", "tam": Vector2(1.4, 1.1), "paleta": ["#a8503a", "#e6c58f", "#34464f"]},
	{"id": "relleno_roda", "titulo": "Obra de la colección", "autor": "Juan Antonio Roda", "anio": "", "tam": Vector2(1.2, 1.5), "paleta": ["#22252b", "#8c8f96", "#c7b89b"]},
	{"id": "relleno_cardenas", "titulo": "Obra de la colección", "autor": "Santiago Cárdenas", "anio": "", "tam": Vector2(1.6, 1.2), "paleta": ["#dfe3e6", "#7d8790", "#2c3136"]},
	{"id": "relleno_caballero", "titulo": "Obra de la colección", "autor": "Luis Caballero", "anio": "", "tam": Vector2(1.8, 1.3), "paleta": ["#d9d0c0", "#6a5c4d", "#1f1b18"]},
	{"id": "relleno_santa_maria", "titulo": "Obra de la colección", "autor": "Andrés de Santa María", "anio": "", "tam": Vector2(1.2, 1.2), "paleta": ["#3f6b4f", "#d69c4b", "#7f3f2f"]},
	{"id": "relleno_salcedo", "titulo": "Obra de la colección", "autor": "Doris Salcedo", "anio": "", "tam": Vector2(1.5, 1.1), "paleta": ["#4a4340", "#a59a8d", "#1c1917"]},
	{"id": "relleno_munoz", "titulo": "Obra de la colección", "autor": "Óscar Muñoz", "anio": "", "tam": Vector2(1.1, 1.4), "paleta": ["#bfbfbf", "#5c5c5c", "#141414"]},
	{"id": "relleno_rojas", "titulo": "Obra de la colección", "autor": "Miguel Ángel Rojas", "anio": "", "tam": Vector2(1.3, 1.3), "paleta": ["#b0413e", "#e9d8a6", "#264653"]},
	{"id": "relleno_morelos", "titulo": "Obra de la colección", "autor": "Delcy Morelos", "anio": "", "tam": Vector2(1.7, 1.2), "paleta": ["#7b2d26", "#3c1a14", "#c08552"]},
	{"id": "relleno_ramirez", "titulo": "Obra de la colección", "autor": "Eduardo Ramírez Villamizar", "anio": "", "tam": Vector2(1.2, 1.2), "paleta": ["#efefef", "#bdbdbd", "#333333"]},
]

## Coleccionables: opcionales, se guardan en el bolso y se pueden leer.
const COLECCIONABLES: Array[Dictionary] = [
	{
		"id": "macuquina", "nombre": "Macuquina de 8 reales", "epoca": "Santa Fe, 1663", "forma": "moneda",
		"texto": "Moneda de plata cortada y golpeada a mano: por eso ninguna es redonda ni igual a otra. La Casa de Moneda de Santa Fe se fundó en 1621, y hoy el Museo Casa de Moneda hace parte del mismo complejo cultural del Banco de la República que este museo.",
	},
	{
		"id": "macuquina_oro", "nombre": "Macuquina de oro", "epoca": "Santa Fe, 1627", "forma": "moneda",
		"texto": "En 1627 se acuñó en Santafé la primera macuquina de oro. La plata y el oro del Nuevo Reino se convertían en moneda para la Corona: la riqueza de esta tierra ya salía del país mucho antes de que existiera el país.",
	},
	{
		"id": "moneda_patria_boba", "nombre": "Moneda de la Patria Boba", "epoca": "Hacia 1810-1816", "forma": "moneda",
		"texto": "En plena pelea entre neogranadinos y con poco oro disponible, la Casa de Moneda tuvo que fabricar monedas para que ambos bandos financiaran el conflicto. Hasta la guerra entre hermanos hubo que pagarla.",
	},
	{
		"id": "billete_mil_dias", "nombre": "Billete de la Guerra de los Mil Días", "epoca": "1899-1902", "forma": "billete",
		"texto": "El Decreto 520 de 1899 permitió emitir todo el dinero que el gobierno necesitara para la guerra. Fue la única hiperinflación colombiana del siglo XX. En 1905, la Ley 19 ordenó cambiar el papel moneda por oro a razón de cien por uno: cien pesos de esta guerra valían uno.",
	},
	{
		"id": "billete_1923", "nombre": "Billete del Banco de la República", "epoca": "Años veinte", "forma": "billete",
		"texto": "Tras la misión Kemmerer, el Banco de la República abrió en julio de 1923 como único autorizado para emitir dinero en el país. Ese mismo banco reunió desde 1957 la colección que hoy cuelga en estas salas.",
	},
	{
		"id": "recorte_arango", "nombre": "Recorte: Débora Arango", "epoca": "1940 y 1955", "forma": "documento",
		"texto": "Sus desnudos y su crítica política escandalizaron al país. Su exposición de 1940 en el Teatro Colón es recordada como desmontada por la presión de Laureano Gómez y la sociedad bogotana, aunque una biografía reciente sostiene que él la atacó sin llegar a cerrarla. Lo seguro: en 1955 el gobierno de Franco clausuró su muestra en Madrid.",
	},
	{
		"id": "recorte_espada", "nombre": "Recorte: la espada de Bolívar", "epoca": "1974-1991", "forma": "documento",
		"texto": "El 17 de enero de 1974 el M-19 se llevó de la Quinta de Bolívar la espada atribuida al Libertador. La devolvió el 31 de enero de 1991 como parte de los acuerdos de paz y quedó bajo custodia del Banco de la República. En Colombia ya se han robado la historia antes, y también para hacer política.",
	},
	{
		"id": "ficha_quimbaya", "nombre": "Ficha: Tesoro Quimbaya", "epoca": "1893-hoy", "forma": "documento",
		"texto": "Más de cien piezas de oro saqueadas de tumbas en el Quindío hacia 1890 y regaladas en 1893 por el presidente Carlos Holguín a la reina regente de España. En 2017 la Corte Constitucional ordenó buscar su restitución; en 2024 Colombia las pidió formalmente; en junio de 2026 el gobierno puso el reclamo en pausa. Siguen en Madrid.",
	},
]


## Ruta de la imagen real de una pieza, o "" si todavía no llega.
static func imagen(id: String) -> String:
	for ext: String in ["jpg", "png", "jpeg", "webp"]:
		var ruta: String = "res://arte/%s.%s" % [id, ext]
		if ResourceLoader.exists(ruta):
			return ruta
	return ""


static func museo(id: String) -> Dictionary:
	for m: Dictionary in MUSEOS:
		if m["id"] == id:
			return m
	return {}


static func obra(id: String) -> Dictionary:
	for o: Dictionary in OBRAS:
		if o["id"] == id:
			return o
	return {}
