#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May  4 10:55:55 2021

@author: tomslab
"""

import csv
from argparse import ArgumentParser

def reading_gff(path):
    
    result = []
    file = open(path, 'r')
    
    for line in file:
        
        line = line.strip().split('\t')
        
        try:
            
            if line[2] == 'gene':
                
                subline = line[8].split(';')
                line[8] = 'gene_id "' + subline[0].split('=')[1] +'";'
                # print(line[8])
                
                
            else:
                
                subline = line[8].split(';')
                line[8] = 'gene_id "' + subline[1].split('=')[1] +'"; transcript_id "' +  subline[0].split('=')[1] +'";'
                
            result.append(line)
      
        except:
            
            # print(line)
            result.append(line)
            
    return(result)

#enddef

def escritura(lista, nombre):

    archivo = open(nombre, 'w')
    archivo.close()    
    
    for linea in lista:
        
        with open(nombre, mode='a') as result_file:
            line_writer = csv.writer(result_file, delimiter='\t', quotechar='@', quoting=csv.QUOTE_MINIMAL)
        
            line_writer.writerow(linea)      
               
#enddef
            
'''MAIN PROGRAM'''

parser = ArgumentParser (
)

parser.add_argument(
    '-gff','--gff',
    dest='gff',
    action='store',
    required=True,
    help='Path of the gff file.'
    )

parser.add_argument(
    '-gtf','--gtf',
    dest='gtf',
    action='store',
    required=True,
    help='Path of the gtf file that is going to be generated.'
    )


args = parser.parse_args ()

path = args.gff
output = args.gtf

result = reading_gff(path)
escritura(result, output)