#!/usr/bin/env python3 
# 4-space indented, v0.0.1
# File name: omark_splice_file.py
# Description: Make a text file of protein isoforms to use as input to Omark.
# Author: Robert Linder
# Date: 2024-08-27

import argparse
import re 

def parse_args():
	"""this enables users to provide input as command line arguments to minimize the need for directly modifying the script; please enter '-h' to see the full list of options"""
	parser = argparse.ArgumentParser(description="Map chromosome names to the patched assembly")
	parser.add_argument("protein_fasta", type=str, help="fasta file of annotated proteins")
	args = parser.parse_args()
	return args

def make_splice_file(fasta):
    """Iterate through the fasta headers to make a text file of isoforms"""
    isoform_dict = {}
    with open(fasta, 'r') as fa, open("isoforms.splice", 'w') as output:
        for line in fa:
             if line.startswith('>'):
                full_name = line[1:].rstrip()
                gene = full_name.split('.')
                gene = '.'.join(gene[0:2])
                if gene in isoform_dict:
                    isoform_dict[gene].append([full_name])
                else:
                    isoform_dict[gene] = [[full_name]]
        for k,v in isoform_dict.items():
            if len(v) > 1:
                new_line = ';'.join([inner for outer in v for inner in outer])
            else:
                new_line = v[0][0]
            output.write(f"{new_line}\n")

def main():
    inputs = parse_args()
    fasta =  inputs.protein_fasta
    make_splice_file(fasta)

if __name__ =="__main__":
    main()