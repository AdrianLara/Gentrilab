;;;;;;;;;Modelo de Gentrificación;;;;;;;;;;;
;;;;;;;;;    Gale Soft UCE       ;;;;;;;;;;;



breed [propietarios propietario]     ;; Conjunto de propietarios
breed[inquilinos inquilino]          ;; Conjunto de inquilinos
globals[                             ;; Variables globales manejadas por el municipio, satisfacción promedio y controladores de tiempo para métodos
  impuesto
  seguridad
  permisos
  satis-promedio
  arr
  ]
patches-own[          ;; Características de los patches que van a representar los inmuebles
  precio              ;; Precio de los inmmuebles
  renta               ;; Valor de Renta del Inmueble
  estado              ;; Estado en el que se encuentra el inmueble
  tipo                ;; Referente a si es una vivienda, casa cultural o comercio
  inquilino?          ;; Propiedad que indica si habitan en los diferentes inmuebles
  zona1

  evaluaEstado        ;; Variable para evaluar cuando una casa debe cambiar de estado
  evaluaTipo          ;; Variable para evaluar el tipo de un inmueble
  ]
propietarios-own[     ;; Características de los propietarios
  satisfaccion        ;; Nivel de satisfaccion de los propietarios
  nivelVida           ;; Nivel de vida de los propietarios
  compromiso          ;; Compromiso social por parte de los propietarios
  dondehabita         ;; Referene al inmueble en donde se encuentra el inquilino
  ]
inquilinos-own[       ;; Características de los inquilinos
  satisfaccion        ;; Nivel de satisfacción con el barrio de los inquilinos
  nivelVida           ;; Nivel de vida de los inquilinos
  compromiso          ;; Compromiso social de los inquilinos con el barrio
  dondehabita         ;; Referene al inmueble en donde se encuentra el inquilino
]
to setup              ;; Se configura el entorno de acuerdo a los parámetros iniciales
  clear-all
  reset-ticks
  ask patches [set pcolor 49]
  pintarCalles
  Municipio

  colocarInmuebles n-of (inmuebles-ini) zona zona
  colocarInquilinos n-of (count patches with [tipo = 1]) tipo-1 1
  colocarInquilinos n-of (count patches with [tipo = 3]) tipo-3 1
  set arr 1
  ask patches with [estado != 0][if (any? inquilinos-on patches) [set inquilino? true]]

end

to go

  if (ticks != 0)[
    if (ticks mod 6 = 0)   [ask inquilinos [evalua-satis]]                                             ;;Evalua Satisfaccion
    if (ticks mod 36 = 0)  [ask n-of (inmuebles-ini - (inmuebles-ini * 0.1)) patches [deterioroCasa]]
    if (ticks mod 12 = 0)  [ask patches [arreglarCasa ]]
    if (ticks mod 12 = 0 and any? patches with [tipo = 1])[ask n-of 1 patches with [tipo = 1][cambiarTipo]]
    ifelse (impuesto > 15)
    [if (ticks mod 5 = 0)[ask n-of 5 inquilinos [vendeInmueble]] ]
    [if (ticks mod 18 = 0)[ask n-of 5 inquilinos [vendeInmueble]] ]
  ]
  ask patches [coloresPatche]
  if (count patches with [inquilino? = false] > 0)[ comprarInmueble]
  tick
end

to Municipio  ;; Método que asigna los valores que se rigen de acuerdo al Agente Municipio
  set impuesto precision ((interes-privado * 12) + 12) 5                           ;; Impuesto en base al interés privado
  set seguridad precision (1 / (interes-privado + 0.1)) 5                          ;; Seguridad en base al interés privado
  set permisos precision (((1 / (interes-privado + 1)) + (1 / impuesto)) * 10) 5   ;; Permisos en base al interés privado e impuestos
  crt 1
  [set shape "municipio"             ;; Representación gráfica del Municipio
   set color gray
    set xcor 0
    set ycor 0
    set size 4
  ]

end

to colocarInmuebles[p z] ;;Método para la creación de inmuebles de acuerdo a la variable global inmuebles-ini

   ask p [
     set inquilino? false                                ;; Variable que indica si hay o no un habitante ahí
     set estado 1 + random 5                            ;; Característica que me indica el estado del inmueble 1: Malo 2: Regular 3:Bueno 4:Muy Bueno 5:Excelente
     ifelse random 100 < distribucion            ;; Cohesión social distribuidad de acuerdo a una variable global
     [set tipo 1]
     [set tipo 3]                                       ;; Asignación de colores de acuerdo al tipo
     if tipo = 1 [set pcolor 25]                        ;; Tipo 1 = Vivienda
     if tipo = 2 [set pcolor 35]                        ;; Tipo 2  = Casa Social
     if tipo = 3 [set pcolor 45]                        ;; Tipo 3 = Centro Comercial

     set precio 1000 + (1000 * impuesto * estado / 5) + random (1000)            ;; Precio del inmueble de acuerdo al impuesto y a cada estado
     set renta (precio * 0.1) / 12                                               ;; Renta del inmueble si es alquilado
     set evaluaEstado 0                                                          ;; Variable de control del estado del inmueble
     set zona1 z
     ]
end

to colocarInquilinos [p m]  ;; Método para la creación de inquilinos de acuerdo a la variable global inquilinos-ini
  ask p [sprout-inquilinos 1[
      set shape "person"
      set dondehabita patch-here
      set satisfaccion 0
    ifelse (m > 0)
    [
      set color 10
      ifelse random 100 < nivel-vida
      [set nivelVida 3]
      [set nivelVida 1 + random 2]
    ]
    [
      set shape "pelucon"
      set size 1.5
      set color white
      set nivelVida 3
    ]
  ]
  ]
end

to colocarPropietarios [p]  ;; Método para la creación de inquilinos de acuerdo a la variable global inquilinos-ini
  ask p [sprout-propietarios 1[
      set shape "person"
      set color 15
      set dondehabita patch-here
      set satisfaccion 0
      ifelse random 100 < nivel-vida
      [set nivelVida 3]
      [set nivelVida 1 + random 2]
      ]
  ]
end

to evalua-satis
  ;;Evaluar la satisfacción de acuerdo a la homogeneidad de los vecinos en cuanto al estado de los inmuebles
  ;;tomando en cuenta también la seguridad, permisos e impuestos del barrio.
  if (estado = 5)  [set satisfaccion (((count patches in-radius 10 with [estado = 5 or estado = 4])) / inmuebles-ini
                                   - ((count patches in-radius 10 with [estado = 3 or estado = 2 or estado = 1])) / inmuebles-ini) * 10 + seguridad + permisos - impuesto
                    ]

  if (estado = 4)  [set satisfaccion (((count patches in-radius 10 with [estado = 5 or estado = 4 or estado = 3])) / inmuebles-ini
                                   - ((count patches in-radius 10 with [estado = 2 or estado = 1])) / inmuebles-ini ) * 10 + seguridad + permisos - impuesto

                    ]

  if (estado = 3)  [set satisfaccion (((count patches in-radius 10 with [estado = 4 or estado = 3 or estado = 2])) / inmuebles-ini
                                   - ((count patches in-radius 10 with [estado = 5 or estado = 1])) / inmuebles-ini ) * 10 + seguridad + permisos - impuesto
                    ]

  if (estado = 2)  [set satisfaccion (((count patches in-radius 10 with [estado = 3 or estado = 2 or estado = 1])) / inmuebles-ini
                                   - ((count patches in-radius 10 with [estado = 5 or estado = 4])) / inmuebles-ini) * 10 + seguridad + permisos - impuesto
                    ]

  if (estado = 1)  [set satisfaccion (((count patches in-radius 10 with [estado = 1 or estado = 2])) / inmuebles-ini
                                   - ((count patches in-radius 10 with [estado = 3 or estado = 4 or estado = 5])) / inmuebles-ini) * 10 + seguridad + permisos - impuesto
                    ]
  ifelse(satisfaccion > 0)[set compromiso true][set compromiso false]

end


to arreglarCasa
  if(estado != 0)                                                                        ;;Arreglar casa de acuerdo a umbrales por nivel de vida
  [set evaluaEstado ((permisos + [nivelVida] of one-of inquilinos-here ) / estado)]
  if ( evaluaEstado > 7 and estado <= 5 and [nivelVida] of one-of inquilinos-here = 1 )    ;; Condiciones para Nivel de  vida 1
  [set estado estado + 1]
  if ( evaluaEstado > 4 and estado <= 5 and [nivelVida] of one-of inquilinos-here = 2 )    ;; Condiciones para Nivel de vida 2
  [set estado estado + 1]
  if ( evaluaEstado > 3.5 and estado <= 5 and [nivelVida] of one-of inquilinos-here = 3 )  ;; Condiciones para Nivel de vida 3
  [set estado estado + 1]
end

to deterioroCasa                                ;; Deterioro de casa cada cierto tiempo
  if(estado > 1)[ set estado estado - 2 ]
end

to cambiarTipo
  set satis-promedio precision ((sum [satisfaccion] of inquilinos ) / inmuebles-ini) 5  ;; Satisfacción promedio de todos los habitantes

    if(satis-promedio < 0 )[                                    ;; Condición para inmuebles de tipo 1 que se convierten en tipo 3
      set tipo tipo + 2
      ;ask n-of 1 patches with [tipo = 3][set tipo tipo - 2]
      ]
end

to vendeInmueble
if (nivelVida = 1)[
  if ([estado] of dondehabita >= 3 and satisfaccion < 0)[
      set inquilino? false
      die
      ]
    ]
  if (nivelVida = 2)[
  if ([estado] of dondehabita > 3 and satisfaccion < -1)[
      set inquilino? false
      die
      ]
    ]
end

to comprarInmueble
  colocarInquilinos n-of (count patches with [inquilino? = false]) inmueblevacio -1
  ask patches with [estado != 0][if (any? inquilinos-on patches) [set inquilino? true]]
end


to pintarCalles
  let u -22
  repeat 10
  [
   ask patches[

      if (pxcor > u and pxcor < u + 2 )[set pcolor black ]
      if (pycor > u and pycor < u + 2 )[set pcolor black ]
  ]
    set u u + 6
  ]
end


;;Reporte de los inmuebles de acuerdo al estado
to-report barrio
  report patches with [pcolor = 49]
end

to-report inm-est-1                   ;; Método que devuelve los inmuebles con estado 1 (malo)
  report patches with [pcolor = 98]
end

to-report inm-est-2                   ;; Método que devuelve los inmuebles con estado 2 (regular)
  report patches with [pcolor = 87]
end

to-report inm-est-3                   ;; Metodo que devuelve los inmuebles con estado 3 (medio)
  report patches with [pcolor = 76]
end

to-report inm-est-4                   ;; Metodo que devuelve los inmuebles con estado 4 (bueno)
  report patches with [pcolor = 65]
end

to-report inm-est-5                   ;; Metodo que devuelve los inmuebles con estado 5 (excelente)
  report patches with [pcolor = 54]
end

;;Reporte de los patches de acuerdo al tipo

to-report tipo-1                   ;; Metodo que devuelve los inmuebles Tipo 1 (Vivienda)
  report patches with [pcolor = 25]
end

to-report tipo-2                   ;; Metodo que devuelve los inmuebles Tipo 2 (Casa Social)
  report patches with [pcolor = 35]
end

to-report tipo-3                   ;; Metodo que devuelve los inmuebles Tipo 3 (Centro Comercial)
  report patches with [pcolor = 45]
end
to-report inmueblevacio
  report patches with [inquilino? = false]
end

to-report zona
  report patches with [pcolor = 49]
end

to coloresPatche
  if(control-ColorInmuebles = "Estado")
  [
     if estado = 1 [set pcolor 98]                                ;; Asignación de colores de acuerdo al estado
     if estado = 2 [set pcolor 87]
     if estado = 3 [set pcolor 76]
     if estado = 4 [set pcolor 65]
     if estado = 5 [set pcolor 54]
  ]
  if (control-ColorInmuebles = "Tipo")
  [
     if tipo = 1 [set pcolor 25]                                ;; Asignación de colores de acuerdo al tipo
     if tipo = 2 [set pcolor 35]                                ;; Tipo 1 = Vivienda   Tipo 2  = Casa Social   Tipo 3 = Centro Comerciali
     if tipo = 3 [set pcolor 45]
  ]


end
@#$#@#$#@
GRAPHICS-WINDOW
289
11
942
485
-1
-1
15.0
1
15
1
1
1
0
0
0
1
-21
21
-15
15
1
1
1
months
1.0

BUTTON
8
11
151
45
SETUP
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

SLIDER
12
68
285
101
inmuebles-ini
inmuebles-ini
1
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
10
225
285
258
interes-privado
interes-privado
0
1
0.9
0.1
1
NIL
HORIZONTAL

BUTTON
154
10
284
43
GO
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

PLOT
953
172
1274
322
Tipo de Inmueble
Tipo
Cantidad
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Vivienda" 1.0 0 -955883 true "" "plot count patches with [tipo = 1]"
"Centro Comercial" 1.0 0 -1184463 true "" "plot count patches with [tipo = 3]"

PLOT
951
334
1275
484
Satisfacción
Satisfaccion
Cantidad
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Alta" 1.0 0 -7858858 true "" "plot count inquilinos with [satisfaccion > 9]"
"Media" 1.0 0 -955883 true "" "plot count inquilinos with [satisfaccion > 0 and satisfaccion < 9]"
"Baja" 1.0 0 -4528153 true "" "plot count inquilinos with [satisfaccion < 0]"
"General" 1.0 0 -987046 true "" "plot (sum [satisfaccion] of inquilinos) / inmuebles-ini"

PLOT
955
10
1274
160
Estado Inmuebles
Tiempo
Estado
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Estado 1" 1.0 0 -5516827 true "" "plot count patches with [estado = 1 ]"
"Estado 2" 1.0 0 -6759204 true "" "plot count patches with [estado = 2 ]"
"Estado 3" 1.0 0 -11881837 true "" "plot count patches with [estado = 3 ]"
"Estado 4" 1.0 0 -13840069 true "" "plot count patches with [estado = 4 ]"
"Estado 5" 1.0 0 -13210332 true "" "plot count patches with [estado = 5 ]"

SLIDER
10
170
285
203
distribucion
distribucion
1
100
90.0
1
1
NIL
HORIZONTAL

SLIDER
11
115
285
148
nivel-vida
nivel-vida
1
100
8.0
1
1
NIL
HORIZONTAL

TEXTBOX
172
376
322
394
NIL
11
0.0
1

CHOOSER
9
274
284
319
control-ColorInmuebles
control-ColorInmuebles
"Tipo" "Estado"
0

PLOT
7
336
285
486
Habitantes
Habitantes
Número
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hab. Iniciales" 1.0 0 -16777216 true "" "plot count turtles with [shape = \"person\"]"
"Hab. Nuevos" 1.0 0 -5825686 true "" "plot count turtles with [shape = \"pelucon\"]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

municipio
false
0
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 180 105 240
Rectangle -16777216 true false 195 180 255 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 105 45 180 90
Rectangle -16777216 false false 105 45 180 90
Polygon -13345367 true false 120 150 120 105 135 105 150 120 165 105 180 105 180 150 165 150 165 120 150 135 135 120 135 150 120 150
Rectangle -13345367 true false 15 165 30 255
Rectangle -13345367 true false 0 165 45 180
Rectangle -13345367 true false 255 165 300 180
Rectangle -13345367 true false 270 165 285 255

pelucon
false
0
Polygon -1 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -11221820 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -1 true false 110 5 80
Rectangle -1 true false 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 150 135 150 165
Circle -16777216 true false 135 180 30
Polygon -11221820 false false 60 195 105 90
Polygon -6459832 true false 105 45 210 45 210 30 195 30 180 0 120 0 105 30 90 30 90 45 105 45 150 45

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment_UIO" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="336"/>
    <metric>count turtles with [shape = "person"]</metric>
    <metric>count turtles with [shape = "pelucon"]</metric>
    <metric>count patches with [tipo = 1]</metric>
    <metric>count patches with [tipo = 3]</metric>
    <metric>count patches with [tipo = 1 and ticks = 1]</metric>
    <metric>count patches with [tipo = 1 and ticks = 3]</metric>
    <enumeratedValueSet variable="interes-privado">
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inmuebles-ini">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribucion">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nivel-vida">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_BA" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="276"/>
    <metric>count turtles with [shape = "person"]</metric>
    <metric>count turtles with [shape = "pelucon"]</metric>
    <metric>count patches with [tipo = 1]</metric>
    <metric>count patches with [tipo = 3]</metric>
    <enumeratedValueSet variable="interes-privado">
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inmuebles-ini">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribucion">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nivel-vida">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_HAB" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="120"/>
    <metric>count turtles with [shape = "person"]</metric>
    <metric>count turtles with [shape = "pelucon"]</metric>
    <metric>count patches with [tipo = 1]</metric>
    <metric>count patches with [tipo = 3]</metric>
    <enumeratedValueSet variable="interes-privado">
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inmuebles-ini">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distribucion">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nivel-vida">
      <value value="71"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
