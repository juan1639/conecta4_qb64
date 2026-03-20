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

CONST VEL_CAER_FICHA = 10
CONST PAUSA_IA_TIRAR = 200

CONST FPS = 60

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
DIM SHARED gameover AS _BIT
DIM restart AS _BIT
DIM salir AS _BIT

DIM SHARED score AS INTEGER ' 0= ganador-jugador, 1= ganador-IA, 2= empate
DIM SHARED columna AS INTEGER
DIM SHARED ficha_cayendo AS _BIT
DIM SHARED pausa_ia AS _BIT

DIM a AS INTEGER
DIM b AS INTEGER
DIM SHARED cadencia AS INTEGER
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
DIM sonido_errorbeep AS LONG

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
'--------               UPDATES GRAFICOS                 --------
'--------                                               --------
'---------------------------------------------------------------
tablero_tile = _LOADIMAGE("tablero-tile-c4.png")
ficha_roja = _LOADIMAGE("ficha-roja-c4.png")
ficha_verde = _LOADIMAGE("ficha-verde-c4.png")

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
sonido_errorbeep = _SNDOPEN("sound-of-error-beep.mp3")

'===============================================================
'--------                                               --------
'--------               UPDATES GENERALES               --------
'--------                                               --------
'---------------------------------------------------------------
DO
    pre_juego = -1
    turno = INT(RND * 2) - 1 ' Turno inicial aleatorio
    gameover = 0
    restart = 0
    salir = 0

    score = 0 '          0= enJuego, 1= ganador-jugador, 2= ganador-IA, 3= empate
    ficha_cayendo = 0
    pausa_ia = 0

    cadencia = 0
    ciclos = 0

    IF NOT turno THEN
        cadencia = PAUSA_IA_TIRAR
        pausa_ia = -1
    END IF

    resetear_board board()

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
            IF turno THEN ini_tirar_ficha raton
        END IF

        '------------- CONTADORES --------------------
        ciclos = ciclos + 1

        IF ciclos >= 32000 THEN ciclos = 0
        IF cadencia > 0 THEN cadencia = cadencia - 1

        '--------- TIRADA IA (SI PROCEDE) ------------
        IF pausa_ia AND cadencia = 0 THEN ini_tirar_ficha raton

        _DISPLAY
        PCOPY 1, _DISPLAY

    LOOP UNTIL gameover OR salir

    '============================================================
    _SNDSTOP musica_ingame

    IF score = 1 THEN _SNDPLAY sonido_aplausoseagle
    IF score >= 2 THEN _SNDPLAY sonido_errorbeep

    '============================================================
    '--------                                            --------
    '--------      B U C L E   G A M E  O V E R          --------
    '--------                                            --------
    '============================================================
    DO
        _LIMIT FPS
        PCOPY _DISPLAY, 1

        IF _KEYDOWN(27) THEN salir = -1 'ESC. Salir
        IF _KEYDOWN(13) THEN restart = -1 ' Jugar otra vez

        '------------- LLAMADAS A SUBS ---------------
        dibuja_board
        mostrar_marcadores
        show_gameover

        '------------- CONTADORES --------------------
        ciclos = ciclos + 1

        IF ciclos >= 32000 THEN ciclos = 0
        IF cadencia > 0 THEN cadencia = cadencia - 1

        _DISPLAY
        PCOPY 1, _DISPLAY

    LOOP UNTIL salir OR restart

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

                _PUTIMAGE (fondo_grid_x, fondo_grid_y), ficha_verde

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

    '-----------------------------------------------------------
    '---       SELECCIONAR TIRA JUGADOR O TIRA IA
    '-----------------------------------------------------------
    IF turno THEN
        columna = INT(raton.x / TILE_X) + 1

    ELSE
        pausa_ia = 0

        '---------------------------------------------------
        ' CHECKEAR SI IA TIENE 4RAYA Y GANA DIRECTO...
        '---------------------------------------------------
        check_si_ia_4raya

        IF columna >= 1 AND columna <= 7 THEN
            '-------- IA hace 4 en raya y gana directo ---------

        ELSE
            '---------------------------------------------------
            ' TIRADA ALEATORIA (como ultimo recurso)
            '---------------------------------------------------
            columna = INT(RND * 7) + 1

        END IF

    END IF

    '-------------- SI COLUMNA LLENA... RETURN ----------------
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


    '---------- SI NOT FICHA_CAYENDO... RETURN -----------
    IF NOT ficha_cayendo THEN EXIT SUB

    '---------------- TIRAR FICHA SI PROCEDE -------------
    ficha.x = (columna - 1) * TILE_X
    ficha.y = ficha.y + VEL_CAER_FICHA

    IF turno THEN
        _PUTIMAGE (ficha.x, ficha.y), ficha_roja

    ELSEIF NOT turno THEN

        _PUTIMAGE (ficha.x, ficha.y), ficha_verde
    END IF

    '---------------- CHECK FICHA DEBAJO -----------------
    IF INT(ficha.y / TILE_Y) + 1 < NRO_FILAS + 1 THEN

        IF board(columna, INT(ficha.y / TILE_Y) + 1).valor <> 0 THEN
            cambiar_turno board(), ficha
        END IF

    END IF

    '-----------------  CHECK LIMITE BAJO ----------------
    IF ficha.y >= NRO_FILAS * TILE_Y THEN cambiar_turno board(), ficha

END SUB

'=======================================================================
SUB cambiar_turno (board() AS board, ficha AS ficha)

    SHARED sonido_chipscollide1 AS LONG
    SHARED sonido_chipscollide2 AS LONG
    SHARED sonido_chipscollide3 AS LONG

    ficha_cayendo = 0

    IF turno THEN
        board(columna, INT(ficha.y / TILE_Y)).valor = 1
        check_4raya
        turno = 0
        cadencia = PAUSA_IA_TIRAR
        pausa_ia = -1

    ELSE
        board(columna, INT(ficha.y / TILE_Y)).valor = 2
        check_4raya
        turno = -1
    END IF

    _SNDPLAY sonido_chipscollide1
    _SNDPLAY sonido_chipscollide2

END SUB

'=======================================================================
SUB check_4raya

    DIM y AS INTEGER
    DIM x AS INTEGER

    DIM loop_4 AS INTEGER
    DIM contador AS INTEGER
    DIM ficha_roja_verde AS INTEGER

    SHARED board() AS board

    '------------------------------------------------------------------
    '---           QUE FICHA CHECKEAR? (ROJA O VERDE)
    '------------------------------------------------------------------
    IF turno THEN
        ficha_roja_verde = 1
    ELSEIF NOT turno THEN
        ficha_roja_verde = 2
    END IF

    '------------------------------------------------------------------
    '---                   CHECK HORIZONTALES
    '------------------------------------------------------------------
    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            contador = 0

            FOR loop_4 = 0 TO 3

                IF x + loop_4 <= NRO_COLUMNAS THEN
                    IF board(x + loop_4, y).valor = ficha_roja_verde THEN contador = contador + 1
                END IF

            NEXT loop_4

            IF contador >= 4 THEN
                score = ficha_roja_verde
                gameover = -1
                EXIT SUB
            END IF

        NEXT x
    NEXT y

    '------------------------------------------------------------------
    '---                   CHECK VERTICALES
    '------------------------------------------------------------------
    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            contador = 0

            FOR loop_4 = 0 TO 3

                IF y + loop_4 <= NRO_FILAS THEN
                    IF board(x, y + loop_4).valor = ficha_roja_verde THEN contador = contador + 1
                END IF

            NEXT loop_4

            IF contador >= 4 THEN
                score = ficha_roja_verde
                gameover = -1
                EXIT SUB
            END IF

        NEXT x
    NEXT y

    '------------------------------------------------------------------
    '---              CHECK DIAGONALES (hacia derecha y abajo)
    '------------------------------------------------------------------
    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            contador = 0

            FOR loop_4 = 0 TO 3

                IF y + loop_4 <= NRO_FILAS AND x + loop_4 <= NRO_COLUMNAS THEN
                    IF board(x + loop_4, y + loop_4).valor = ficha_roja_verde THEN contador = contador + 1
                END IF

            NEXT loop_4

            IF contador >= 4 THEN
                score = ficha_roja_verde
                gameover = -1
                EXIT SUB
            END IF

        NEXT x
    NEXT y

    '------------------------------------------------------------------
    '---           CHECK DIAGONALES (hacia izquierda y arriba)
    '------------------------------------------------------------------
    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            contador = 0

            FOR loop_4 = 0 TO -3 STEP -1

                IF y + ABS(loop_4) <= NRO_FILAS AND x + loop_4 >= 1 THEN
                    IF board(x + loop_4, y + ABS(loop_4)).valor = ficha_roja_verde THEN contador = contador + 1
                END IF

            NEXT loop_4

            IF contador >= 4 THEN
                score = ficha_roja_verde
                gameover = -1
                EXIT SUB
            END IF

        NEXT x
    NEXT y

    check_empate

END SUB

'=======================================================================
SUB check_empate

    DIM y AS INTEGER
    DIM x AS INTEGER

    SHARED board() AS board

    FOR y = 1 TO NRO_FILAS
        FOR x = 1 TO NRO_COLUMNAS

            IF board(x, y).valor = 0 THEN EXIT SUB

        NEXT x
    NEXT y

    '-- SI LLEGA HASTA AQUI HAY  E M P A T E  (todas casillas llenas) --
    score = 3 '  --- Empate ---
    gameover = -1

END SUB

'=======================================================================
SUB check_si_ia_4raya

    DIM y AS INTEGER
    DIM x AS INTEGER

    DIM a AS INTEGER
    DIM b AS INTEGER

    DIM loop_4 AS INTEGER
    DIM contador AS INTEGER
    DIM ficha_roja_verde AS INTEGER

    SHARED board() AS board

    '------------------------------------------------------------------
    columna = -99
    ficha_roja_verde = 2

    FOR a = 1 TO NRO_COLUMNAS

        FOR b = NRO_FILAS TO 1 STEP -1

            IF board(a, b).valor = 0 THEN
                board(a, b).valor = 2
                EXIT FOR
            END IF

        NEXT b

        '------------------------------------------------------------------
        '---                   CHECK HORIZONTALES
        '------------------------------------------------------------------
        FOR y = 1 TO NRO_FILAS
            FOR x = 1 TO NRO_COLUMNAS

                contador = 0

                FOR loop_4 = 0 TO 3

                    IF x + loop_4 <= NRO_COLUMNAS THEN
                        IF board(x + loop_4, y).valor = ficha_roja_verde THEN contador = contador + 1
                    END IF

                NEXT loop_4

                IF contador >= 4 THEN
                    columna = a
                    board(a, b).valor = 0 ' Dejar la casilla como estaba (SIN ficha)
                    EXIT SUB
                END IF

            NEXT x
        NEXT y

        '------------------------------------------------------------------
        '---                   CHECK VERTICALES
        '------------------------------------------------------------------
        FOR y = 1 TO NRO_FILAS
            FOR x = 1 TO NRO_COLUMNAS

                contador = 0

                FOR loop_4 = 0 TO 3

                    IF y + loop_4 <= NRO_FILAS THEN
                        IF board(x, y + loop_4).valor = ficha_roja_verde THEN contador = contador + 1
                    END IF

                NEXT loop_4

                IF contador >= 4 THEN
                    columna = a
                    board(a, b).valor = 0 ' Dejar la casilla como estaba (SIN ficha)
                    EXIT SUB
                END IF

            NEXT x
        NEXT y

        '------------------------------------------------------------------
        '---              CHECK DIAGONALES (hacia derecha y abajo)
        '------------------------------------------------------------------
        FOR y = 1 TO NRO_FILAS
            FOR x = 1 TO NRO_COLUMNAS

                contador = 0

                FOR loop_4 = 0 TO 3

                    IF y + loop_4 <= NRO_FILAS AND x + loop_4 <= NRO_COLUMNAS THEN
                        IF board(x + loop_4, y + loop_4).valor = ficha_roja_verde THEN contador = contador + 1
                    END IF

                NEXT loop_4

                IF contador >= 4 THEN
                    columna = a
                    board(a, b).valor = 0 ' Dejar la casilla como estaba (SIN ficha)
                    EXIT SUB
                END IF

            NEXT x
        NEXT y

        '------------------------------------------------------------------
        '---           CHECK DIAGONALES (hacia izquierda y arriba)
        '------------------------------------------------------------------
        FOR y = 1 TO NRO_FILAS
            FOR x = 1 TO NRO_COLUMNAS

                contador = 0

                FOR loop_4 = 0 TO -3 STEP -1

                    IF y + ABS(loop_4) <= NRO_FILAS AND x + loop_4 >= 1 THEN
                        IF board(x + loop_4, y + ABS(loop_4)).valor = ficha_roja_verde THEN contador = contador + 1
                    END IF

                NEXT loop_4

                IF contador >= 4 THEN
                    columna = a
                    board(a, b).valor = 0 ' Dejar la casilla como estaba (SIN ficha)
                    EXIT SUB
                END IF

            NEXT x
        NEXT y

        board(a, b).valor = 0 ' Dejar la casilla como estaba (SIN ficha)

    NEXT a

END SUB

'=======================================================================
SUB show_gameover

    LOCATE 3, 27

    IF score = 1 THEN
        PRINT " E N H O R A B U E N A !     4 EN RAYA "
    ELSEIF score = 2 THEN
        PRINT " P E R D I S T E !   IA HIZO 4 EN RAYA "
    ELSEIF score = 3 THEN
        PRINT "   E    M    P    A    T    E    !   "
    END IF


    LOCATE 5, 20
    PRINT " Pulse Enter para jugar otra vez o Esc para salir... "

END SUB

'=======================================================================
SUB mostrar_marcadores

    'COLOR amarillo_ui
    'LOCATE 6, 1
    'PRINT raton.x; " - "; raton.y

    IF cadencia > 0 AND NOT gameover THEN
        COLOR blanco
        LOCATE 4, 38
        PRINT " IA pensando... "
    END IF

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
SUB resetear_board (board() AS board)

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
















