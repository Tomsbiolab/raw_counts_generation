#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr  3 11:28:45 2020

@author: luis
"""

from argparse import ArgumentParser
import csv
from os import scandir
from os.path import abspath

def ls(ruta):
    return [abspath(arch.path) for arch in scandir(ruta) if arch.is_file()]

def lectura_archivos(lista):
    
    no_10 = 0
    no_5 = 0
    no_2 = 0
    suma_porcentajes = 0
    
    resultado = [['Librería','Total reads','Assigned reads','No assigned reads','% assigned reads']]
    for archivo in lista:
        
        nombre = archivo.split('.summary')[0]
        no_asignadas = 0
        lectura = open(archivo, 'r')
        
        for line in lectura:
            
            line = line.strip()
            linea = line.split('\t')
            
            if linea[0] == 'Assigned':
                
                asignadas = int(linea[1])
                
            else:
                
                try:
                    
                    numero = int(linea[1])
                    no_asignadas = no_asignadas + numero
                    
                except:
                    
                    continue
        
        if asignadas < 10000000:
            
            no_10 = no_10 +1
            
        if asignadas < 5000000:
            
            no_5 = no_5 +1
            
        if asignadas < 2500000:
            
            no_2 = no_2+1
            
        total = no_asignadas + asignadas
        porcentaje = (asignadas/total)*100
        suma_porcentajes = suma_porcentajes + porcentaje
        cuarteto = [nombre, total, asignadas, no_asignadas, porcentaje]
    
        resultado.append(cuarteto)
        
    total_archivos = len(lista)
    media_archivos = suma_porcentajes/total_archivos
        
    return(resultado, media_archivos, no_10, no_5, no_2)
                        
#enddef
            
def escritura(lista, nombre):
    
    archivo = open(nombre,'w')
    archivo.close() 
    
    for linea in lista:
        if len(linea)>1:
#            print(linea)
        
            with open(nombre, mode='a') as result_file:
                line_writer = csv.writer(result_file, delimiter='\t', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        
                line_writer.writerow(linea)

parser = ArgumentParser (
)

parser.add_argument(
    '-p','--path',
    dest='path',
    action='store',
    required=True,
    help='Path to the folder that contains the matrix counts files.'
    )

args = parser.parse_args ()

ruta = args.path

lista = ls(ruta)

resultado, media, no10, no5, no2 = lectura_archivos(lista)

output = ruta+'/resumen_feature_counts.txt'
escritura(resultado, output)

output = ruta+'/media_feature_counts.txt'

archivo = open(output,'w')

archivo.write('The media of assigned reads is '+str(media)+'\n')
archivo.write('Number of libraries with less than 10 M alignments: '+str(no10)+'\n')
archivo.write('Number of libraries with less than 5 M alignments: '+str(no5)+'\n')
archivo.write('Number of libraries with less than 2.5 M alignments: '+str(no2)+'\n')
archivo.close()

