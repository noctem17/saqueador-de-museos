class_name Catalogo
extends RefCounted
## Todo el contenido histórico del juego. Para corregir un texto o agregar una
## pieza solo hay que tocar este archivo. Las fuentes están en docs/FUENTES.md.
##
## "imagen": si existe res://arte/<id>.jpg (o .png), el juego la usa en el cuadro.
## Si no, dibuja un cuadro provisional con los colores de "paleta".

const OBRAS: Array[Dictionary] = [
	{
		"id": "violencia", "titulo": "Violencia", "autor": "Alejandro Obregón", "anio": "1962",
		"tipo": "pintura", "tam": Vector2(2.4, 1.3),
		"paleta": ["#3b3f45", "#6d7278", "#1d1f22"],
		"razon": "Ese cuadro le recuerda a la gente lo que pasó. Mejor que se les olvide.",
		"texto": "Primer premio de pintura en el Salón Nacional de Artistas de 1962. Una mujer mutilada y encinta, cuyo rostro, seno y vientre forman un paisaje de montañas grises. Obregón no muestra a los asesinos: solo a la víctima de la violencia bipartidista que vivió Colombia desde finales de los años cuarenta.",
	},
	{
		"id": "decoracion", "titulo": "Decoración de interiores", "autor": "Beatriz González", "anio": "1981",
		"tipo": "pintura", "tam": Vector2(2.2, 1.6),
		"paleta": ["#2f7d5b", "#e8d9a0", "#b5472f"],
		"razon": "Una cortina burlándose de un presidente. Con el poder no se juega.",
		"texto": "Serigrafía sobre tela que repite, como un estampado de cortina, una foto de prensa del presidente Julio César Turbay cantando en una fiesta. La artista convirtió la imagen del poder en un objeto de decoración, en plena época de estado de sitio.",
	},
	{
		"id": "retratos_mudos", "titulo": "Retratos mudos", "autor": "Beatriz González", "anio": "",
		"tipo": "pintura", "tam": Vector2(1.5, 1.5),
		"paleta": ["#c9a227", "#5a3e2b", "#efe6c8"],
		"razon": "Esas caras ya no tienen voz. Que tampoco tengan pared.",
		"texto": "Beatriz González tomó imágenes de la prensa y la historia colombiana para pintar lo que el país prefiere no mirar. Figura entre las obras destacadas en la selección de cien tesoros del museo.",
	},
	{
		"id": "mandolina", "titulo": "Mandolina", "autor": "Fernando Botero", "anio": "1957",
		"tipo": "pintura", "tam": Vector2(1.5, 1.2),
		"paleta": ["#d98b2b", "#7a3b1d", "#f0d9a8"],
		"razon": "Con ese cuadro empezó todo. Sin el primero, los demás no significan nada.",
		"texto": "Llegó en 1957 con la donación de la V Reunión de Bancos Centrales del Continente Americano, en el origen de la colección de arte del Banco de la República. Quitarla es arrancar la primera página de la historia del museo.",
	},
	{
		"id": "monjas", "titulo": "Monjas muertas", "autor": "Atribuido a Victorino García Romero", "anio": "ca. 1809",
		"tipo": "pintura", "tam": Vector2(1.1, 1.5),
		"paleta": ["#1c1a1a", "#b9a98f", "#6b1f1f"],
		"razon": "Doscientos años mirando desde esa pared. Ya estuvo bueno.",
		"texto": "Parte de un conjunto de doce pinturas de monjas muertas de hacia 1809, atribuidas a Victorino García Romero, con sala especial en el museo. Es memoria de la vida religiosa y de la muerte en el Nuevo Reino, justo antes de la Independencia.",
	},
	{
		"id": "chatarra", "titulo": "Chatarra", "autor": "Feliza Bursztyn", "anio": "",
		"tipo": "escultura", "tam": Vector2(1.0, 1.4),
		"paleta": ["#5c5f63", "#8a6a4f"],
		"razon": "A ella ya la sacaron del país una vez. Terminemos el trabajo.",
		"texto": "Bursztyn fue pionera de la escultura en chatarra en Colombia desde 1961. En 1981, bajo el estado de sitio, los militares la detuvieron e interrogaron por supuestos vínculos con el M-19 que nunca se probaron. Se asiló en la embajada de México y murió en París en enero de 1982, a los 48 años.",
	},
	{
		"id": "negret", "titulo": "Aparato mágico", "autor": "Édgar Negret", "anio": "",
		"tipo": "escultura", "tam": Vector2(0.9, 1.2),
		"paleta": ["#c23a2b", "#20262e"],
		"razon": "Parece una máquina y no sirve para nada. Peor: pone a pensar.",
		"texto": "Negret, nacido en Popayán, fue uno de los maestros de la escultura moderna colombiana. Sus Aparatos mágicos, hechos en metal con tornillos y tuercas a la vista, unen la técnica industrial con el misterio. Tiene lugar en la sala de maestros del siglo XX.",
	},
	{
		"id": "lechuga", "titulo": "La Lechuga", "autor": "José de Galaz", "anio": "1700-1707",
		"tipo": "objeto", "tam": Vector2(0.45, 0.8),
		"paleta": ["#d4af37", "#1f8a4c"],
		"razon": "La joya de la corona. Esa sí me la trae intacta.",
		"texto": "Custodia de la iglesia de San Ignacio de Bogotá, en oro con 1.485 esmeraldas, además de rubíes, diamantes, perlas y amatistas. Los jesuitas la vendieron al Banco de la República en los años ochenta: las fuentes dan 1985 o 1987. En 2015 salió de Colombia por primera vez para exhibirse en el Prado.",
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


static func obra(id: String) -> Dictionary:
	for o: Dictionary in OBRAS:
		if o["id"] == id:
			return o
	return {}
