# raw_counts_generation

This pipeline is able to download, trimm, align and extract raw counts from all the SRA runs contained in the third column of the metadata file that the user gives to the script (example in "metadata_example.csv").

The pipeline is controlled by the master script named "slurm_sra_to_counts_8.sh". This script has some parameters that should be changed by the user in each execution:

1- v_genome: Name reference genome file that is going to be used for doing the alignment. This name has to be given with the file format (i.e. "PN40024_VCost_genome.fasta")

2- v_anotacion: Name of the annotation file to use without the format extension.

3- genome_folder: Folder where the scripts of this pipeline are storaged

4- metadata_file: Path to the file that contains the metadata of the SRA runs that are going to be analyzed

5- results_folder: Path to the folder where all the outputs of this pipeline are going to be generated
