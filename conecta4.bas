'---------------------------------------------------------------------------
'---                                                                     ---
'---                          C O N E C T A  4                           ---
'---                                                                     ---
'---                 Programado por: Juan Eguia, 2026                    ---
'---                                                                     ---
'===========================================================================
'---                       C O N S T A N T E S                           ---
'---                                                                     ---
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

CONST VEL_CAER_FICHA = 2

CONST FPS = 100

'===========================================================================
'---                       Variables  O B J E T O S
'---
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
'---                                                                 ---
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
DIM SHARED columna AS INTEGER
DIM SHARED ficha_cayendo AS _BIT

DIM a AS INTEGER
DIM b AS INTEGER
DIM cadencia AS INTEGER
DIM ciclos AS INTEGER

DIM tablero_tile AS LONG
DIM ficha_roja AS LONG
DIM ficha_verde AS LONG

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

_TITLE " CONECTA 4  by Juan Eguia "

LOCATE 18, 38
PRINT " Cargando... "

'===============================================================
'--------               UPDATES GENERALES               --------
'--------                                               --------
'---------------------------------------------------------------
pre_juego = -1
turno = -1
cambio_turno = 0
game_over = 0
salir = 0

score = 0 '          0= enJuego, 1= ganador-jugador, 2= ganador-IA, 3= empate
ficha_cayendo = 0

cadencia = 0
ciclos = 0

instanciar_board board()

'===============================================================
'--------               UPDATES GRAFICOS                 --------
'--------                                               --------
'---------------------------------------------------------------
tablero_tile = _LOADIMAGE("tablero-tile-c4.png")
ficha_roja = _LOADIMAGE("ficha-roja-c4.png")
ficha_verde = _LOADIMAGE("ficha-roja-c4.png")

'===============================================================
'--------               UPDATES SONIDOS                 --------
'--------                                               --------
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
CLS
LINE (0, 0)-(WINDOW_X, WINDOW_Y), negro_vacio, BF

DO
    _LIMIT FPS
    PCOPY _DISPLAY, 1

    '------------- LLAMADAS A SUBS ---------------
    dibuja_board
    mostrar_marcadores

    '---------------------------------------------
    IF _KEYDOWN(27) THEN SYSTEM

    COLOR amarillo
    LOCATE 3, 30
    PRINT " C O N E C T A   C U A T R O "

    COLOR blanco
    LOCATE 5, 31
    PRINT " Pulse ENTER para comenzar "

    _DISPLAY
    PCOPY 1, _DISPLAY

LOOP UNTIL _KEYDOWN(13) OR _KEYDOWN(32)

'============================================================
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
        tirar_ficha
        dibuja_board
        mostrar_marcadores

        '----- TECLAS ESC, M  Y  CLICK-RATON (TIRAR FICHA) -----
        IF _KEYDOWN(27) THEN salir = -1
        IF _KEYDOWN(77) OR _KEYDOWN(109) THEN _SNDSTOP musica_ingame

        WHILE _MOUSEINPUT
            raton.x = _MOUSEX
            raton.y = _MOUSEY
        WEND

        IF (_MOUSEBUTTON(1) OR _MOUSEBUTTON(2)) AND NOT ficha_cayendo THEN
            ini_tirar_ficha raton
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
_SNDSTOP musica_ingame

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
    SHARED tablero_tile AS LONG
    SHARED ficha_roja AS LONG
    SHARED ficha_verde AS LONG

    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            fondo_grid_x = (x - 1) * TILE_X
            fondo_grid_y = y * TILE_Y

            IF board(x, y).valor = 1 THEN

                _PUTIMAGE (fondo_grid_x, fondo_grid_y), ficha_roja

            ELSEIF board(x, y).valor = 2 THEN

                _PUTIMAGE (fondo_grid_x, fondo_grid_y), ficha_roja

            END IF

            '------- DIBUJA SIEMPRE LA PORCION DEL TABLERO -------
            _PUTIMAGE (fondo_grid_x, fondo_grid_y), tablero_tile

        NEXT x
    NEXT y

END SUB

'=======================================================================
SUB ini_tirar_ficha (raton AS raton)

    SHARED board() AS board
    SHARED ficha AS ficha

    '-------------- SI COLUMNA LLENA... RETURN ----------------
    columna = INT(raton.x / TILE_X) + 1

    IF board(columna, 1).valor <> 0 THEN EXIT SUB

    '-------------- SI SE PUEDE, INICIA TIRADA ----------------
    ficha_cayendo = -1
    ficha.x = (columna - 1) * TILE_X
    ficha.y = 1 * TILE_Y

    'LOCATE 3, 60: PRINT columna; " - "; board(columna, 1).valor

END SUB

'=======================================================================
SUB tirar_ficha

    SHARED ficha AS ficha
    SHARED board() AS board
    SHARED ficha_roja AS LONG
    SHARED ficha_verde AS LONG

    SHARED sonido_chipscollide1 AS LONG
    SHARED sonido_chipscollide2 AS LONG
    SHARED sonido_chipscollide3 AS LONG

    '---------- SI NOT FICHA_CAYENDO... RETURN -----------
    IF NOT ficha_cayendo THEN EXIT SUB

    '---------------- TIRAR FICHA SI PROCEDE -------------
    ficha.x = (columna - 1) * TILE_X
    ficha.y = ficha.y + VEL_CAER_FICHA

    _PUTIMAGE (ficha.x, ficha.y), ficha_roja

    '---------------- CHECK FICHA DEBAJO -----------------
    IF INT(ficha.y / TILE_Y) + 1 < NRO_FILAS + 1 THEN

        IF board(columna, INT(ficha.y / TILE_Y) + 1).valor <> 0 THEN

            ficha_cayendo = 0
            board(columna, INT(ficha.y / TILE_Y)).valor = 1
            _SNDPLAY sonido_chipscollide1
            _SNDPLAY sonido_chipscollide2

        END IF
    END IF

    '-----------------  CHECK LIMITE BAJO ----------------
    IF ficha.y >= NRO_FILAS * TILE_Y THEN

        ficha_cayendo = 0
        board(columna, INT(ficha.y / TILE_Y)).valor = 1
        _SNDPLAY sonido_chipscollide1
        _SNDPLAY sonido_chipscollide3

    END IF

END SUB

'=======================================================================
SUB mostrar_marcadores

    'COLOR amarillo_ui
    'LOCATE 6, 1
    'PRINT raton.x; " - "; raton.y

    COLOR amarillo
    LOCATE 1, 1
    PRINT " Alt+ENTER: ";

    COLOR blanco
    PRINT "Pantalla Completa"

    IF pre_juego THEN EXIT SUB

    '--------------------------------------------------
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

    '-- ASIGNAR VALOR=0 (SIN FICHA por defecto) A LAS 42 CASILLAS --
    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            board(x, y).valor = 0 ' 0= vacio (SIN ficha)

        NEXT x
    NEXT y

END SUB

'===================================================================
SUB instanciar_ficha (ficha AS ficha)
    ficha.x = 0
    ficha.y = 0
END SUB
















