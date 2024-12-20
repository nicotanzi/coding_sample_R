##############################################################
#####   DATA MANIPULATION: CLEANING, VAR GEN, GROUPING   #####
#####                AUTHOR: NICOL�S TANZI               #####
##############################################################

# Libraries ----
library(tidyverse)
library(dplyr)
library(survey)
library(srvyr)
library(scales)
library(haven)

# Load data ----
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) # where the file is located
hl <- read_sav("hl.sav")
hl_dic <- labelled::lookfor(hl) 

# IDHOGAR ----

hl$HH1 <- sprintf("%04d", hl$HH1)
hl$HH2 <- sprintf("%02d", hl$HH2)
hl <- hl  %>%
  mutate(idhogar =  paste(HH1,HH2, sep="", collapse = NULL))

##########################
###      Formatting    ###
###    2, 1 => 0, 1    ###
##########################

hl <- hl  %>%
  mutate(
    # Sexo
    HL4=replace_na(HL4,1),
    HL4_t  = NA, HL4_t  = replace(HL4_t,  HL4  == 1, 1), HL4_t  = replace(HL4_t,  HL4  == 2, 0),
    
    # Edad
    HL6=replace(HL6,  HL6  > 95, NA), # convertir en NA lo que no conocemos
    
    # Asistencia Escolar
    asistio  = 0, asistio  = replace(asistio,  ED3  == 2, 1),
    asiste  = 0, asiste  = replace(asiste,  ED3  == 1, 1)
    
  )
hl$HL4<-hl$HL4_t


#####################################
###   New Individual Variables    ###
#####################################

# Es padre de algún niño del hogar
hl<-hl %>%
  group_by(idhogar) %>% 
  mutate(es_padre= as.numeric( (HL1 %in% HL12 | HL1 %in% HL14) ) )

# Es niño 
hl<-hl %>% mutate(ninio= as.numeric( HL6>4 & HL6<18 ))

# Adulto que no es padre - otro_ad
hl <- hl %>% 
  mutate( otro_ad = as.numeric(HL6>17)*(1-es_padre) )

# Años de Educación
hl <- hl %>%
  mutate( ED4B_t=replace_na(ED4B,0),
          ED4B_t=replace(ED4B_t, ED4B_t  > 20 , 0) ) %>% 
  mutate( edu=0,edu=case_when(
    
    # Primario
    ED4A==01 & ED4B_t < 6 ~ 0+ED4B_t, # primaria incompleta
    ED4A==01 & ED4B_t > 7 ~ 0+ED4B_t, # si se pasa de 7, entonces poneme 7 (completa)
    ED4A==02 ~ 7, # primaria completa
    
    # EGB
    ED4A==03 & ED4B_t < 9 ~ 0+ED4B_t, # EGB incompleta
    ED4A==03 & ED4B_t > 8 ~ 0+ED4B_t, # si se pasa de 8, entonces poneme 9 (completa)
    ED4A==04 ~ 9, # EGB completa
    
    # Secundario incompleto con primaria de 6 a�os
    ED4A==05 & ED4B_t < 5 ~ 6+ED4B_t,
    ED4A==05 & ED4B_t > 4 ~ 12, # si se pasa de 5, entonces poneme 12 (completa)
    
    # Secundario incompleto con primaria de 7 a�os
    ED4A==06 & ED4B_t < 5 ~ 7+ED4B_t,
    ED4A==06 & ED4B_t > 4 ~ 12, # si se pasa de 4, entonces poneme 12 (completa)
    
    # Polimodal incompleto
    ED4A==08 & ED4B_t < 3 ~ 9+ED4B_t,
    ED4A==08 & ED4B_t > 2 ~ 12, # si se pasa de 2, entonces poneme 12 (completa)
    
    # Secundario/Polimodal completo
    ED4A==07 ~ 12,
    ED4A==09 ~ 12,
    
    # Terciario o Universitario completo o incompleto
    ED4A==10 ~ 13,
    ED4A==11 ~ 12,
    ED4A==12 ~ 12,
    ED4A==13 ~ 12,
    
    # Posgrado
    ED4A==14 ~ 17
    
  ))


##############################
###   TO HOUSEHOLD LEVEL   ###
##############################

hlid <- hl %>% select(idhogar) %>% unique()

# TIENE NI��OS EL HOGAR - ninios
A <- hl %>% group_by(idhogar) %>%
  summarise(ninios=any(HL6<18 & HL6>4)) %>% 
  mutate(ninios=as.numeric(ninios))
A<-left_join(hlid,A) %>% mutate(ninios=replace_na(ninios,0))
hl_hh<-A

# Pctje de hombres en el hogar
A <- hl %>% group_by(idhogar) %>%
  summarise(sexo=mean(HL4_t,na.rm=TRUE))
hl_hh<-left_join(hl_hh,A)

# Pctje de ni�os varones en el hogar sexo_ninios
A <- hl %>% filter(ninio==1) %>% group_by(idhogar) %>%
  summarise(sexo_ninios=mean(HL4_t,na.rm=TRUE))
A<-left_join(hlid,A) %>% mutate(sexo_ninios=replace_na(sexo_ninios,0.5))
hl_hh<-left_join(hl_hh,A)

# Edad promedio del hogar
A <- hl %>% group_by(idhogar) %>%
  summarise(edad=mean(HL6,na.rm=TRUE))
A<-left_join(hlid,A) %>% mutate(edad=replace_na(edad,0))

# Edad promedio de los niños del hogar - edad_ninios
A <- hl %>% filter(ninio==1) %>% group_by(idhogar) %>%
  summarise(edad_ninios=mean(HL6,na.rm=TRUE))
A<-left_join(hlid,A) %>% mutate(edad_ninios=replace_na(edad_ninios,0))
hl_hh<-left_join(hl_hh,A)


# El/la jefe/a del hogar es p/madre de todos los niños del hogar - jefe_padre
A <- hl %>% filter(ninio==1) %>% group_by(idhogar) %>%
  summarise(jefe_padre=all(HL3==03)) %>% 
  mutate(jefe_padre=as.numeric(jefe_padre))
A<-left_join(hlid,A) %>% mutate(jefe_padre=replace_na(jefe_padre,0))
hl_hh<-left_join(hl_hh,A)

# Hay por lo menos un niño sin su mamá viviendo en el hogar - sinmama
A <- hl %>% group_by(idhogar) %>%
  summarise(sinmama=any(HL12==00,na.rm = TRUE)) %>% 
  mutate(sinmama=as.numeric(sinmama))
hl_hh<-left_join(hl_hh,A)

# Hay por lo menos un niño sin su papá viviendo en el hogar - sinpapa
A <- hl %>% group_by(idhogar) %>%
  summarise(sinpapa=any(HL14==00,na.rm = TRUE)) %>% 
  mutate(sinpapa=as.numeric(sinpapa))
hl_hh<-left_join(hl_hh,A)

# Hay por lo menos un niño que no tiene ningún padre viviendo en el hogar - sinpadres
A <- hl %>% group_by(idhogar) %>%
  summarise(sinpadres=any(HL14==00 & HL12==00,na.rm = TRUE)) %>% 
  mutate(sinpadres=as.numeric(sinpadres))
hl_hh<-left_join(hl_hh,A)

# Hay adultos que no son padres de los niños del hogar viviendo en el hogar - otros_ad
A <- hl %>% group_by(idhogar) %>%
  summarise(otros_ad=any(otro_ad==1,na.rm = TRUE)) %>% 
  mutate(otros_ad=as.numeric(otros_ad))
hl_hh<-left_join(hl_hh,A)

# Cantidad de adultos que no son padres de los niños del hogar - cant_otros
A <- hl %>% group_by(idhogar) %>%
  summarise(cant_otros=sum(otro_ad,na.rm = TRUE))
hl_hh<-left_join(hl_hh,A)

# Edad promedio de los adultos que no son padres de los niños del hogar - edad_otros
A <- hl %>% filter(otro_ad==1) %>% group_by(idhogar) %>%
  summarise(edad_otros=mean(HL6,na.rm = TRUE))
A<-left_join(hlid,A) %>% mutate(edad_otros=replace_na(edad_otros,0))
hl_hh<-left_join(hl_hh,A)

# Pctje de hombres en los adultos que no son padres de los niños del hogar - sexo_otros
A <- hl %>% filter(otro_ad==1) %>% group_by(idhogar) %>%
  summarise(sexo_otros=mean(HL4_t,na.rm = TRUE))
A<-left_join(hlid,A) %>% mutate(sexo_otros=replace_na(sexo_otros,0))
hl_hh<-left_join(hl_hh,A)

# Algun niño tiene diferente padre o madre que el resto - dif_padres
A <- hl %>% filter(ninio==1) %>% group_by(idhogar) %>%
  summarise(c_madres=n_distinct(HL12),c_padres=n_distinct(HL14)) %>% 
  mutate(dif_padres= as.numeric( c_madres>1 | c_padres>1 ) ) ; A<-A[,-c(2,3)]
A<-left_join(hlid,A) %>% mutate(dif_padres=replace_na(dif_padres,0))
hl_hh<-left_join(hl_hh,A)

# Algun miembro del hogar jamás asistió a la escuela - alg_no_edu
A <- hl %>% group_by(idhogar) %>%
  summarise(alg_no_edu=any(asistio==0 & asiste==0)) %>% 
  mutate(alg_no_edu=as.numeric(alg_no_edu))
hl_hh<-left_join(hl_hh,A)

# Cuantos miembros del hogar jamás asistieron a la escuela - n_no_edu
A <- hl %>% group_by(idhogar) %>%
  summarise(n_no_edu=sum(asistio==0 & asiste==0))
hl_hh<-left_join(hl_hh,A)

# Cuantos niños del hogar jamás asistieron a la escuela - ninio_no_edu
A <- hl %>% filter (ninio==1) %>% group_by(idhogar) %>%
  summarise(ninio_no_edu=sum(asistio==0 & asiste==0))
A<-left_join(hlid,A) %>% mutate(ninio_no_edu=replace_na(ninio_no_edu,0.5))
hl_hh<-left_join(hl_hh,A)

# Media de la edad menos los años estudiados de los niños - atraso
A <- hl %>% filter(ninio==1) %>% mutate(atraso=HL6-edu-5) %>% 
  group_by(idhogar) %>%
  summarise(atraso=mean(atraso,na.rm=TRUE))
A<-left_join(hlid,A) %>% mutate(atraso=replace_na(atraso,0))
hl_hh<-left_join(hl_hh,A)
