# Libraries ----
library(tidyverse)
library(dplyr)
library(survey)
library(srvyr)
library(scales)
library(ggthemes)
library(haven)
library(fastDummies)

# Load data ----
hl <- read_sav("data/hl.sav")
hl_dic <- labelled::lookfor(hl) 

# IDHOGAR ----

hl$HH1 <- sprintf("%04d", hl$HH1)
hl$HH2 <- sprintf("%02d", hl$HH2)
hl <- hl  %>%
  mutate(idhogar =  paste(HH1,HH2, sep="", collapse = NULL))

#########################
###      Binarias     ###
###    2, 1 a 0, 1    ###
#########################

hl <- hl  %>%
  mutate(
    # Sexo
    HL4=replace_na(HL4,1),
    HL4_t  = NA, HL4_t  = replace(HL4_t,  HL4  == 1, 1), HL4_t  = replace(HL4_t,  HL4  == 2, 0),
    
    # Edad
    HL6=replace(HL6,  HL6  > 95, NA), # convertir en NA lo que no conocemos
    
    
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
    
    # Secundario incompleto con primaria de 6 aÃ±os
    ED4A==05 & ED4B_t < 5 ~ 6+ED4B_t,
    ED4A==05 & ED4B_t > 4 ~ 12, # si se pasa de 5, entonces poneme 12 (completa)
    
    # Secundario incompleto con primaria de 7 aÃ±os
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
