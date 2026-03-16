'---------------------------------------------------------------------------
'---                                                                     ---
'---                          C O N E C T A  4                           ---
'---                                                                     ---
'---                 Programado por: Juan Eguia, 2026                    ---
'---                                                                     ---
'===========================================================================
'---                       C O N S T A N T E S                           ---
'---------------------------------------------------------------------------
CONST blanco = _RGB32(245, 245, 245)
CONST gris_fondo_ui = _RGB32(99, 99, 99)
CONST gris_borde = _RGB32(166, 166, 166)
CONST gris_oscuro = _RGB32(59, 59, 59)
CONST negro_vacio = _RGB32(60, 60, 60)

CONST amarillo = _RGB32(188, 183, 44)
CONST amarillo_2 = _RGB32(237, 181, 31)

CONST rojo = _RGB32(191, 22, 19)
CONST rojo_2 = _RGB32(139, 17, 0)

CONST azul_osc = _RGB32(17, 11, 139)
CONST azul_osc_2 = _RGB32(5, 5, 89)

CONST azul_cel = _RGB32(11, 161, 194)
CONST azul_cel_2 = _RGB32(17, 105, 139)

CONST amarillo_ui = _RGB32(255, 255, 12)

CONST TILE_X = 100
CONST TILE_Y = 100

CONST NRO_FILAS = 6
CONST NRO_COLUMNAS = 7

CONST WINDOW_X = NRO_COLUMNAS * TILE_X
CONST WINDOW_Y = (NRO_FILAS * TILE_Y) + TILE_Y

CONST FPS = 60

'===========================================================================
'---                       Variables  O B J E T O S
'---------------------------------------------------------------------------
TYPE board
    x AS INTEGER
    y AS INTEGER
    valor AS INTEGER
END TYPE

TYPE ficha
    x AS INTEGER
    y AS INTEGER
END TYPE

TYPE raton
    x AS INTEGER
    y AS INTEGER
END TYPE

'-----------------------------------------------------------------------
'---      A S I G N A R   E S P A C I O   E N   M E M O R I A        ---
'-----------------------------------------------------------------------
DIM ficha AS ficha
DIM board(NRO_COLUMNAS, NRO_FILAS) AS board
DIM SHARED raton AS raton

DIM SHARED pre_juego AS _BIT
DIM SHARED turno AS _BIT
DIM SHARED cambio_turno AS _BIT
DIM SHARED gameover AS _BIT
DIM salir AS _BIT

DIM SHARED score AS INTEGER ' 0= ganador-jugador, 1= ganador-IA, 2= empate

DIM a AS INTEGER
DIM b AS INTEGER
DIM cadencia AS INTEGER
DIM ciclos AS INTEGER

DIM musica_ingame AS LONG
DIM sonido_chipscollide1 AS LONG
DIM sonido_chipscollide2 AS LONG
DIM sonido_chipscollide3 AS LONG
DIM sonido_diethrow1 AS LONG
DIM sonido_diethrow2 AS LONG
DIM sonido_aplausoseagle AS LONG

'===============================================================
'--------                                               --------
'--------            INICIALIZACION GENERAL             --------
'--------                                               --------
'---------------------------------------------------------------
SCREEN _NEWIMAGE(WINDOW_X, WINDOW_Y, 32)

_SCREENMOVE _DESKTOPWIDTH / 2 - _WIDTH / 2, _DESKTOPHEIGHT / 2 - _HEIGHT / 2

_PRINTMODE _KEEPBACKGROUND
RANDOMIZE TIMER

CLS
LINE (0, 0)-(WINDOW_X, WINDOW_Y), negro_vacio, BF

_TITLE " CONECTA 4 "

LOCATE 18, 38
PRINT " Cargando... "

'===============================================================
'--------               UPDATES GENERALES               --------
'---------------------------------------------------------------
pre_juego = -1
turno = -1
cambio_turno = 0
game_over = 0
salir = 0

cadencia = 0
ciclos = 0

instanciar_board board()

'===============================================================
'--------               UPDATES SONIDOS                 --------
'---------------------------------------------------------------
musica_ingame = _SNDOPEN("music-puzzle-game1.mp3")
sonido_aplausoseagle = _SNDOPEN("aplausoseagle.mp3")
sonido_chipscollide1 = _SNDOPEN("chipsCollide1.ogg")
sonido_chipscollide2 = _SNDOPEN("chipsCollide2.ogg")
sonido_chipscollide3 = _SNDOPEN("chipsCollide3.ogg")
sonido_diethrow1 = _SNDOPEN("dieThrow1.ogg")
sonido_diethrow2 = _SNDOPEN("dieThrow2.ogg")

'============================================================
'--------                                            --------
'--------        B U C L E   P R E J U E G O         --------
'--------                                            --------
'============================================================
DO
    _LIMIT FPS
    PCOPY _DISPLAY, 1

    '------------- LLAMADAS A SUBS ---------------
    dibuja_board
    mostrar_marcadores

    '--------- TECLAS ESC Y POS_XY RATON ---------
    IF _KEYDOWN(27) THEN SYSTEM
    IF _KEYDOWN(77) OR _KEYDOWN(109) THEN _SNDSTOP musica_intro

    COLOR amarillo
    LOCATE 3, 30
    PRINT " C O N E C T A   C U A T R O "

    COLOR blanco
    LOCATE 5, 31
    PRINT " Pulse ENTER para comenzar "

    _DISPLAY
    PCOPY 1, _DISPLAY

LOOP UNTIL _KEYDOWN(13) OR _KEYDOWN(32)

pre_juego = 0
soniquete 250, 750

_SNDPLAY musica_ingame

'============================================================
'---                    CAMBIO TURNO                      ---
'---                                                      ---
'------------------------------------------------------------
DO
    '============================================================
    '--------                                            --------
    '--------      B U C L E   P R I N C I P A L         --------
    '--------                                            --------
    '============================================================
    DO
        _LIMIT FPS
        PCOPY _DISPLAY, 1

        '------------- LLAMADAS A SUBS ---------------
        dibuja_board
        mostrar_marcadores

        '--------- TECLAS ESC Y POS_XY RATON ---------
        IF _KEYDOWN(27) THEN salir = -1
        IF _KEYDOWN(77) OR _KEYDOWN(109) THEN _SNDSTOP musica_ingame

        WHILE _MOUSEINPUT
            raton.x = _MOUSEX
            raton.y = _MOUSEY
        WEND

        IF _MOUSEBUTTON(1) OR _MOUSEBUTTON(2) THEN
            'PAINT (raton.x, raton.y), rojo, azul_cel
        END IF

        '------------- CONTADORES --------------------
        ciclos = ciclos + 1

        IF ciclos >= 32000 THEN ciclos = 0
        IF cadencia > 0 THEN cadencia = cadencia - 1

        _DISPLAY
        PCOPY 1, _DISPLAY

    LOOP UNTIL gameover OR salir OR cambio_turno

LOOP UNTIL salir OR gameover

'============================================================
'--------      B U C L E   G A M E  O V E R          --------
'--------                                            --------
'============================================================

DO
    _LIMIT FPS
    PCOPY _DISPLAY, 1

    IF _KEYDOWN(29) THEN salir = -1 'ESC. Salir

    '------------- LLAMADAS A SUBS ---------------
    dibuja_board
    mostrar_marcadores
    'show_gameover

    '------------- CONTADORES --------------------
    ciclos = ciclos + 1

    IF ciclos >= 32000 THEN ciclos = 0
    IF cadencia > 0 THEN cadencia = cadencia - 1

    _DISPLAY
    PCOPY 1, _DISPLAY

LOOP UNTIL salir

'===================================================================
'---                   F I N   P R O G R A M A                   ---
'===================================================================
'salir
BEEP
SYSTEM

'===================================================================
'---                                                             ---
'---                    S U B R U T I N A S                      ---
'---                                                             ---
'-------------------------------------------------------------------
SUB dibuja_board

    DIM y AS INTEGER
    DIM x AS INTEGER
    DIM fondo_grid_x AS INTEGER
    DIM fondo_grid_y AS INTEGER

    SHARED board() AS board

    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            fondo_grid_x = (x - 1) * TILE_X
            fondo_grid_y = y * TILE_Y

            IF board(x, y).valor = 1 THEN

                LINE (fondo_grid_x, fondo_grid_y)-(fondo_grid_x + TILE_X, fondo_grid_y + TILE_Y), azul_cel, BF
                CIRCLE (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), TILE_Y / 2.5, rojo
                PAINT (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), rojo, rojo

            ELSEIF board(x, y).valor = 2 THEN

                LINE (fondo_grid_x, fondo_grid_y)-(fondo_grid_x + TILE_X, fondo_grid_y + TILE_Y), azul_cel, BF
                CIRCLE (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), TILE_Y / 2.5, amarillo_2
                PAINT (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), amarillo_2, amarillo_2

            ELSE

                LINE (fondo_grid_x, fondo_grid_y)-(fondo_grid_x + TILE_X, fondo_grid_y + TILE_Y), azul_cel, BF
                CIRCLE (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), TILE_Y / 2.5, negro_vacio
                PAINT (fondo_grid_x + (TILE_X / 2), fondo_grid_y + (TILE_Y / 2)), negro_vacio, negro_vacio

            END IF

        NEXT x
    NEXT y

END SUB

'=======================================================================
SUB mostrar_marcadores

    COLOR amarillo_ui
    LOCATE 6, 1
    PRINT raton.x; " - "; raton.y

    COLOR amarillo
    LOCATE 1, 1
    PRINT " Alt+ENTER: ";

    COLOR blanco
    PRINT "Pantalla Completa"

    IF pre_juego THEN EXIT SUB

    '-----------------------------------------
    COLOR amarillo
    LOCATE 1, 38
    PRINT " Toggle Music: ";

    COLOR blanco
    PRINT "M"

    COLOR amarillo
    LOCATE 1, 65
    PRINT " Turno: ";

    COLOR blanco

    IF turno THEN PRINT " Jugador " ELSE PRINT " IA "

END SUB

'=======================================================================
SUB soniquete (uno AS INTEGER, dos AS INTEGER)

    DIM a AS INTEGER
    FOR a = uno TO dos STEP 50
        SOUND a, 0.2
    NEXT a

END SUB

'===================================================================
SUB instanciar_board (board() AS board)

    DIM y AS INTEGER
    DIM x AS INTEGER

    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            board(x, y).valor = 0 ' 0= vacio (SIN ficha)

        NEXT x
    NEXT y

END SUB















