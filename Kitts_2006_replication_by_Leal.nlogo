;;;;;;;;;;;;;; GLOBAL VARIABLES ;;;;;;;;;;;;;;
globals
[
 ;;; Variables/parameters used in the original model:

 g       ;-->   parameter representing the benefit created for each n peers who work
 c       ;-->   parameter representing the cost of working for the collective good
 enf     ;-->   constant cost of enforcement ("e" in the paper)
 V       ;-->   group valence (EQ 8. in the paper)

 ;;; Variables/parameters used in the current implementation of the model:

 n-of-peers           ;--> number of peers (N - 1)
 v_i-list             ;--> list of actors' v_i (v_i = actor i's valence of norm enforcement)
 p-equilibrium        ;--> participation at equilibrium -part of the connvergence routine-
 t-equilibrium        ;--> time at equilibrium -part of the connvergence routine-
 equilibrium-count    ;--> number of ticks agent keep track of their past behavior -part of the convegrence routine-
 converged?           ;--> Boolean: did the model converged?
]

;;;;;;;;;;;;;; ACTOR VARIABLES ;;;;;;;;;;;;;;
turtles-own
[
 ;;; Variables/parameters used in the original model:

 n_i        ;-->   total number of peers working (0 <= n <= N -1)
 theta_i    ;-->   a randomly distributed random variable representing actor i's subjective scope of influence (0 <= theta_i <= N - 1)
 n+_i       ;-->   the number of peers that actor i expects to work if she promotes work [n+_i = min(n + theta_i, N - 1)]
 n-_i       ;-->   the number of peers that actor i expects to work because of her downward pressure to work
 v_i        ;-->   actor i's valence of norm enforcemnt
 IW_i       ;-->   actor i's value of the inclination to work function (EQ. 4 in the paper)
 Ppromote_i ;-->   actor i's value of the payoff for promoting function (EQ. 6 in the paper)
 Poppose_i  ;-->   actor i's value of the payoff for opposing function (EQ. 7 in the paper)
 w_i        ;-->   actor i's work choice (EQ. 9 in the paper)

 ;;; Variables/parameters used in the current implementation of the model:

 working-peers-list_i  ;--> agents i's list of peers that are currently working
 history-list-w_i      ;--> agent i's  working (w_i) history
 history-list-v_i      ;--> agent i's  valence of norm enforcement (v_i) history
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; INITIAL CONDITIONS  ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
clear-all                                  ;; clear memory
set-default-shape turtles "face neutral"   ;; make actors look like circles
crt 10                                     ;; create 10 actors
layout-circle turtles 10                   ;; use a circle layout to position the actors

ask turtles
[
 create-links-with other turtles     ;; create a fully connected graph
 set color red                       ;; make actors red
 initial-conditions                  ;; execute the initial-conditions procedure
 set theta_i random 10               ;; make the variable theta a random integer in the range [0,9]
 set working-peers-list_i []         ;; declare working-peers-list_i as an empty list
 set history-list-w_i []             ;; declare history-list-w_i as an empty list
 set history-list-v_i []             ;; declare history-list-v_i as an empty list
 set size ((theta_i * 0.2) + 2)
]

ifelse (experiment1)                 ;; run experiment 1 or 2 according to the user-specified decision
[run-experiment1]
[run-experiment2]

set converged? false                 ;; assume the model has not converged
set n-of-peers (count turtles - 1)   ;; calculate the number of peers
set equilibrium-count 2              ;; set the parameter equilibrium-count, that is, the number of ticks agents keep track of their past behavior -part of the convegrence routine-
reset-ticks
end

to initial-conditions ;; set initial conditions as declared in the article
set w_i 0
set v_i 0
set enf 2
set g 1
set c 5
end

to run-experiment1   ;; set valid inital conditions related to experiment 1
set lambda random 2   ;; randomly make lambda 0 or 1, lambda = 0 will reproduce figure 2 in the paper; lambda = 1 will reproduce digure 3 in the paper
end

to run-experiment2   ;; set valid inital conditions related to experiment 1
set lambda random-float 1 ;; randomly make lambda a number between [0 and 1)
set alpha random-float 1  ;; randomly make alpha a number between  (0 and 1)
if (alpha = 0)
[run-experiment2]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; THE ACTUAL MODEL  ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
ask turtles   ;; all turtles will execute the following procedures:
 [
  compute-peers-currently-working
  compute-inclination-to-work
  compute-group-valence
  compute-decision-to-work
  compute-payoff-for-promoting
  compute-payoff-for-opposing
  compute-promote-or-abstain-or-oppose
 ]

 behavior-history       ;; execute this procedure

 if (ticks > 5)         ;; if more than five ticks have passed
 [
  convergence           ;; execute the convergence procedure
 ]
 ;if ((converged? = true) or (ticks = 10000)) ;; if the model converged or 10,000 ticks have passed:
 if  (ticks = 10000)
 [stop]                                         ;; stop the simulation
 tick                   ;; advance time
end

to compute-peers-currently-working
set working-peers-list_i []    ;; agents generate the list working-peers-list_i, initially it is an empty list

let i 0                        ;; declare the variable i as a local variable
let j 0                        ;; declare the variable j as a local variable
let ego 0                      ;; declare the variable ego as a local variable
let alter 0                    ;; declare the variable alter as a local variable

while [i <= n-of-peers]        ;; while i is less than number of peers
[
 set j 0                       ;; set the local variable j to 0
 while [j <= n-of-peers]       ;; while j is less than node-count.
 [
  set ego turtle i           ;; the variable j represents ego, the focal agent
  set alter turtle j         ;; the variable j represents alter
  if i != j                  ;; if alter is different from ego
  [
   ask ego                  ;; ask ego
   [
    if ([w_i] of alter = 1)  ;; if alter is working
    [
     set working-peers-list_i fput (1) working-peers-list_i ;; put a 1 in the list working-peers-list_i
    ]
    set n_i sum(working-peers-list_i)            ;; sum all the items in the list "working-peers-list_i", which is equivalent to computing the number of i's peers currently working
   ]
  ]
  set j j + 1                ;; go to the next alter
 ]
 set i i + 1                 ;; go to the next ego
]
end

to compute-inclination-to-work
set IW_i ((g - c) + mu * (1 - lambda * (n_i / (n_i + 1))))  ;; see equation 4 in the text
end

to compute-group-valence
set v_i-list []  ;; clear ("forget") what is in the list v_i-list, which is the list of all actors' valence of norm enforcement

let i 0                    ;; the variable i represents ego

while [i <= n-of-peers]    ;; loop through all the turtles
[
 ask turtle i              ;; ask the ith turtle:
 [
  set v_i-list fput (v_i) v_i-list   ;; store your valence of norm enforcemnt in the list v_i-list
 ]
 set i i + 1               ;; go to the next ego
]

set V sum(v_i-list)        ;; compute the group valence by summing up the elements in v_i-list
end


to compute-decision-to-work
ifelse (alpha * V + ((1 - alpha) * IW_i) > 0) ;; compute actor i's decision to work, see equation 9 in the text
  [
   set w_i 1
   set color green
  ]
  [
   set w_i 0
   set color red
  ]
end

to compute-payoff-for-promoting
ifelse ((n_i + theta_i) <= n-of-peers)  ;; compute the number of peers that actor i expects to work if she promotes work [n+_i = min(n + theta_i, N - 1)]
 [set n+_i (n_i + theta_i)]
 [set n+_i n-of-peers]

 set Ppromote_i ((n+_i - n_i) * g - ((n+_i / (n+_i + 1)) - (n_i / (n_i + 1))) * lambda * mu * w_i - enf) ;; see equation 6 in the text
end


to compute-payoff-for-opposing
ifelse ((n_i - theta_i) >= 0)          ;; compute the number of peers that actor i expects to work if she does not promote work [n-_i = max(n - theta_i, 0)]
 [set n-_i (n_i - theta_i)]
 [set n-_i 0]

 set Poppose_i ((n-_i - n_i) * g - ((n-_i / (n-_i + 1)) - (n_i / (n_i + 1))) * lambda * mu * w_i - enf)  ;; see equation 7 in the text
end

to compute-promote-or-abstain-or-oppose
 ifelse ((Ppromote_i >  Poppose_i) and (Ppromote_i >= enf))  ;; if enforcing the preferred norm promises to bring an expected benefit that exceeds the cost, she will enforce [i.e. promote = (v_i = 1)]
 [
  set v_i 1
  set shape "face happy"
 ]
 [
  ifelse ((Poppose_i >  Ppromote_i) and (Poppose_i >= enf))  ;; if opposing the preferred norm promises to bring an expected benefit that exceeds the cost, she will oppose [i.e. promote = (v_i = - 1)]
  [
   set v_i -1
   set shape "face sad"
  ]
  [
    set v_i 0                                                ;; if neither promote nor oppose promises a gain the actor will abstain (v_i = 0)
    set shape "face neutral"
  ]
 ]
end

to-report participation
  report (count turtles with [w_i = 1]) / count turtles      ;; compute the D.V.: proportion participating/working
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONVERGENCE ROUTINE CODE  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to behavior-history
ask turtles
[
 set history-list-w_i lput (w_i) history-list-w_i      ;; actor i will store ("remember") its current working decision (w_i)
 set history-list-v_i lput (v_i) history-list-v_i      ;; actor i will store ("remember") its current value of law enforcement (v_i)
 while [length history-list-w_i > equilibrium-count]      ;; if the number of rounds stored in actor i's memory is > equilibrium count (the user-defined number of rounds actors can remember things):
 [
  set history-list-w_i but-first history-list-w_i      ;; delete actor i's oldest w_i memory
  set history-list-v_i but-first history-list-v_i      ;; delete actor i's oldest v_i memory
 ]
]
end

to convergence
if converged? = false  ;; if the model hasn't yet converged:
[
 let i 0

 ask turtles
 [
  if (item 0 history-list-w_i = item 1 history-list-w_i)  and (item 0 history-list-v_i = item 1 history-list-v_i) ;; add 1 to the counter variable (i) if actor i's past working decision (w_i) and valence of norm enforcement (v_i) are the same as the current values
  [
   set i i + 1
  ]
 ]

 if i = count turtles                      ;; if all actors have the same strategy in the previous and current round:
 [
  set converged? true                        ;; set converged? to true
  set p-equilibrium participation            ;; save current proportion participating as the actual value of the D.V.
  set t-equilibrium ticks + 1                ;; save the value of the current tick/time step
 ]
]
end


;; Collective Action, Rival Incentives, and the Emergence of Antisocial Norms.
;; Code for the model in Kitts 2006
;; Diego Leal, University of Massachusetts (www.diegoleal.info)
;; Last updated: April 2016
@#$#@#$#@
GRAPHICS-WINDOW
6
10
314
339
16
16
9.030303030303031
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
326
13
389
46
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
390
256
423
mu
mu
0
50
0
1
1
(INCENTIVE)
HORIZONTAL

SLIDER
10
435
257
468
alpha
alpha
0
0.98
0.42246121985890317
0.02
1
(COHESIVENESS)
HORIZONTAL

TEXTBOX
272
390
449
432
parameter representing the total value of the incentive (mu >= 0)
11
0.0
1

TEXTBOX
274
479
458
518
parameter representing the rivalness of the incentive (0 <= lambda <= 1)
11
0.0
1

TEXTBOX
270
432
452
488
parameter representing the strength of social influence or group cohesiveness (0 <= alpha < 1)
11
0.0
1

SWITCH
329
120
454
153
experiment1
experiment1
1
1
-1000

SLIDER
9
479
262
512
lambda
lambda
0
1
0.30265681091167906
0.02
1
(RIVALNESS)
HORIZONTAL

BUTTON
405
14
468
47
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
351
57
432
102
NIL
participation
17
1
11

TEXTBOX
46
345
125
370
SHRINK
20
15.0
1

TEXTBOX
201
343
351
368
WORK
20
55.0
1

TEXTBOX
340
207
568
343
NOTES: \n1) Actors's size is a function of their particular scope of influence\n\n2.1) Sad face: Oppose\n2.2) Indifferent face: Abstain\n2.3) Happy face: Promote
15
0.0
1

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
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment_1_FIG_3_reps=100_t=10000" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>participation</metric>
    <enumeratedValueSet variable="experiment1">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="mu" first="0" step="1.5" last="50"/>
    <steppedValueSet variable="alpha" first="0" step="0.03" last="0.98"/>
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
