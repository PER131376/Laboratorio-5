;-----------------------Encabezado--------------------------------------------------------
; Archivo:	        main.s
; Dispositivo:	        PIC16F887
; Autor:	        Selvin Peralta 
; Compilador:	        pic-as (v2.30), MPLABX V5.40
;                
; Programa:	        Contador Hexadecimal y Division de Decenas, Centena y Unidades 
; Hardware:	        LEDs en el puerto A, Display en el puerto C y D
;                       
; Creado:               2 Marzo, 2021
; Última modificación:  6 Marzo, 2021

;---------------------------------------------------------------------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

 UP	EQU 0
 DOWN	EQU 7	
	

  PSECT udata_bank0 ;common memory
    var:	    DS  1 ;1 byte apartado
    display_var:    DS	2 ;2 byte apartado
    display_var2:   DS	2 ;2 byte apartado
    banderas:	    DS  1 ;1 byte apartado
    nibble:	    DS  2 ;2 byte apartado
    cen:	    DS  1 ;1 byte apartado
    cen1:	    DS  1 ;1 byte apartado
    dece:	    DS  1 ;1 byte apartado
    dece1:	    DS  1 ;
    uni:	    DS  1 ;
    uni1:	    DS  1 ;
    V1:		    DS  1 ;
  PSECT udata_shr ;common memory
    w_t:	DS  1;Variable para el w temporal 
    STATUS_t:   DS  1;Variable para el STATUS temporal 
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  
  ;----------------------Macros------------------------------------
  displaydecimal macro   ;Activamos el macros para conparar las variables de la restas al display 
    movf    cen, w       ;Guardamos lo de la variable cen a w
    call    Tabla	 ;Mandamos el w a la verificacion en la tabla 
    movwf   cen1	 ;Mandamos la literal de regreso de la tabla en la variable cen1
    movf    dece, w      ;Guardamos lo de la variable dece a w 
    call    Tabla        ;Mandamos el w a la verificacion en la tabla
    movwf   dece1        ;Mandamos la literal de regreso de la tabla en la variable dece1
    movf    uni, w       ;Guardamos lo de la variable uni a w 
    call    Tabla        ;Mandamos el w a la verificacion en la tabla
    movwf   uni1         ;Mandamos la literal de regreso de la tabla en la variable uni1
    endm
    
  reiniciar_Tmr0 macro   ;Activamos el macros de reinicio de Tmr0
    banksel TMR0         ;Activamos el puerto del timer0
    movlw   237	; 5 ms   ;Tiempo que se guardara para el timer0 en w
    movwf   TMR0         ;Luego guardamos el valor de w a TMR0
    bcf	    T0IF         ;Seteamos la bandera T0IF
    endm
    
  ;----------------------interripción reset------------------------
  ORG 04h		 ;posición 0004h para interr
  push:
    movf    w_t		 ;Guardamos el valor de w en una varaibles temporal    
    swapf   STATUS, W    ;Invertimos los valor del STATUS y lo asignamos a w
    movwf   STATUS_t     ;Guardamos la w anterior a nuestra variable 
    
  isr:                   ;Etiqueta para poder realizar los siguientes comandos en las interrupciones
    btfsc   RBIF         ;Verificamos si hay un cambio en la bandera 
    call    int_ioCB     ;Llamamos al incremento de los push
    
    btfsc   T0IF	 ;Verificamos si hay un cambio en la bandera del tmr0
    call    Interr_Tmr0  ;Llamamos a las interrepciones del tmr0 
    
  pop:
    swapf   STATUS_t, W  ;Cambiamos el valor de la variable STATUS_t a w
    movwf   STATUS       ;Movemos el valor de w a STATUS
    swapf   w_t, F       ;Invertimos el valor de W_t 
    swapf   w_t, W       ;Invertimos el valor de w_t y luego lo guardamos a w
    retfie
;---------SubrutinasInterrupción-----------
int_ioCB:
    banksel PORTB	 ;Llamamos el banco del puerto B
    btfss   PORTB, UP    ;Verificamos si el push esta precionado 
    incf    PORTA        ;incrementamos el puerto A
    btfss   PORTB, DOWN  ;Verificamos si el push de decremento esta precionado 
    decf    PORTA        ;Decrementamos el puerto A
    bcf	    RBIF         ;Ponemos la bandera en 0 
    return
Interr_Tmr0:
    reiniciar_Tmr0	 ;50 ms
    bcf     STATUS, 0    ;Llamamos el banco del STATUS
    clrf    PORTB        ;Limpiamos el puertoB
    btfsc   banderas, 1  ;Verificamos si el bit 1 de la variable esta en 1 
    goto    display0     ;Llamamos a la subrrutina para encender el primer display
    btfsc   banderas, 2  ;Verificamos si el bit 2 de la variable esta en 1 
    goto    display1     ;Llamamos a la subrrutina para encender el segundo display
    btfsc   banderas, 3  ;Verificamos si el bit 3 de la variable esta en 1 
    goto    display_cen  ;Llamamos a la subrrutina para encender el tercer display
    btfsc   banderas, 4  ;Verificamos si el bit 4 de la variable esta en 1 
    goto    display_dec  ;Llamamos a la subrrutina para encender el cuarto display
    btfsc   banderas, 5  ;Verificamos si el bit 5 de la variable esta en 1 
    goto    display_uni  ;Llamamos a la subrrutina para encender el quinto display
    movlw   00000001B    ;Colocamos 1 en el bit 0 
    movwf   banderas     ;lo movemos a la variable banderas 
siguientedisplay:
    RLF	    banderas, 1  ; corremos el numero 1 de la variables al siguiente bit
    return
display0:
    movf    display_var, w
    movwf   PORTC
    bsf	    PORTB, 2 
    goto    siguientedisplay
display1:
    movf    display_var2, w
    movwf   PORTC
    bsf	    PORTB, 3
    goto    siguientedisplay
display_cen: 
    movf    cen1, w
    movwf   PORTD
    bsf	    PORTB, 4
    goto    siguientedisplay
display_dec:
    movf    dece1, w
    movwf   PORTD
    bsf	    PORTB, 5
    goto    siguientedisplay
display_uni:
    movf    uni1, w 
    movwf   PORTD
    bsf	    PORTB,6
    goto    siguientedisplay    
    
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
 ;------------------ TABLA -----------------------
  Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
 
  ;---------------configuración------------------------------
  main: 
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    clrf    TRISA	;PORTA A salida
    clrf    TRISC
    clrf    TRISD
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN
    bcf	    TRISB, 2
    bcf	    TRISB, 3
    bcf	    TRISB, 4
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    	
    call    config_reloj
    call    config_IOChange
    call    config_tmr0
    call    config_InterrupEnable  
    banksel PORTA 
   
;----------loop principal---------------------
 loop:
    movf    PORTA, w
    movwf   var
    movwf   V1
    
    call    separar_nibbles
    call    config_displays
    call    divcentenas
    displaydecimal

    goto    loop    ;loop forever 
;------------sub rutinas--------------------

divcentenas:
    clrf    cen          ;Limpiamos la varaible cen
    movlw   01100100B    ;ASIGNAMOS EL VALOR DE "100" W
    subwf   V1, 1        ;RESTMOS W DE F
    btfss   STATUS,0     ;Verificamos si el CARRY del STATUS esta en 1 
    goto    DECENAS      ;Vamos a la subrrutina DECENAS
    incf    cen, 1       ;Incrementamos 1 a la variable cen 
    goto    $-5          ;Regresa 5 lineas atras 
DECENAS:
    clrf    dece         ;Limpiamos la varaible Dece
    movlw   01100100B    ;Asginamos el valor de "100" W
    addwf   V1           ;Sumamos w a la variable v1
    movlw   00001010B    ;Asignamos el valor de "10" w
    subwf   V1,1         ;Restamos el valor 10 a V1 
    btfss   STATUS,0     ;Verificamos si el CARRY del STATUS esta en 1
    goto    UNIDADES     ;Vamos a la subrrutina UNIDADES
    incf    dece, 1      ;Incrementamos la variable dece 
    goto    $-5          ;Volvemos 5 lineas atras
UNIDADES:
    clrf    uni          ;Limpiamos la varaible uni
    movlw   00001010B    ;Asginamos el valor de "10" W
    addwf   V1           ;Sumamos w a la variable v1
    movlw   00000001B    ;Asignamos el valor de "1" w
    subwf   V1,1         ;Restamos el valor 1 a V1 
    btfss   STATUS, 0    ;Verificamos si el CARRY del STATUS esta en 1
    return               ;Regresamos a donde lo llamamos 
    incf    uni, 1       ;Incrementamos la variable uni
    goto    $-5          ;Volvemos 5 lineas atras
separar_nibbles:
    movf    var, w
    andlw   0x0f
    movwf   nibble
    swapf   var, w
    andlw   0x0f 
    movwf   nibble+1
    return
config_displays:
    movf    nibble, w
    call    Tabla
    movwf   display_var
    movf    nibble+1, w
    call    Tabla
    movwf   display_var2
    return
config_IOChange:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN 
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    bcf	    RBIF
    return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 4Mhz
    return

config_InterrupEnable:
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    bsf	    T0IE
    bcf	    T0IF
    return
 config_tmr0:
    banksel OPTION_REG  ;Banco de registros asociadas al puerto A
    bcf	    T0CS        ;Reloj interno clock selection
    bcf	    PSA	        ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	        ;PS = 111 Tiempo en ejecutar , 256
    
    reiniciar_Tmr0      ;Macro reiniciar tmr0
    return  
    
end