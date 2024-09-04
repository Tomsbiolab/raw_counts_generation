#!/bin/bash

#SBATCH --job-name=SRA_down_all
#SBATCH --output=res_SRA_to_counts_all%j.txt
#SBATCH --partition=long
#SBATCH --time=14-23:00:00
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=20
#SBATCH --mem=100gb

module load python/3.8

#PARAMETERS TO MODIFY

# Reference genome used to do the alignment
v_genome='PN40024_VCost_genome.fasta'

# Annotation version to use (name of the annotation file to use without the format extension).
v_annotation='PN40024_VCost.v3_27'

# Folder where the reference genome and the annotation file are storaged
genome_folder='/storage/TOM/genomas_anotaciones/vitis_vinifera/PN/'

# Folder where the scripts of this pipeline are storaged
scripts_folder='/storage/TOM/SRA_vitis/scripts/GITHUB_index_and_download/'

# Path to the file that contains the metadata of the SRA runs that are going to be analyzed
metadata_file='/storage/TOM/SRA_vitis/metadata/final_classification.csv'

# Path to the folder where all the outputs of this pipeline are going to be generated
results_folder='/storage/TOM/SRA_vitis/test_download'

# DO NOT TOUCH ANYTHING BELOW THIS LINE

cd $genome_folder
mkdir -p "$v_genome"_index
cd "$v_genome"_index

# Checking if the reference genome is already indexed

index_done=$( ls | grep .txt | wc -l)
#echo "# ficheros .txt del genoma indexado de la versión correcta"
echo $index_done
cd .. 

# If reference genome is not indexed, the script performs the indexing

if [[ $index_done -eq 0 ]]
then
echo Indexing reference genome "$v_genome"
STAR --runThreadN 20 --runMode genomeGenerate --genomeSAindexNbases 13 --genomeDir "$v_genome"_index --genomeFastaFiles "$v_genome"
fi

# Checking if there is an available gtf file of the annotations version

gtf_done=$( ls | grep "$v_anotacion".gtf | wc -l)
echo "# GTF file of the annotation"
echo $gtf_done
if [[ $gtf_done -eq 0 ]]
then
echo "Converting from GFF3 to GTF."
python3 "$scripts_folder"gff_to_gtf.py --gff "$v_anotacion".gff3 --gtf "$v_anotacion".gtf
fi

echo "Begining pipeline"

# From this point, the script is going to download a list of sra files, trimm and align the libraries and process the alignments in order to generate a raw count matrix per library

# Generating a list of all the SRA runs to download from the metadata file.

list=$( tail -n +2 $metadata_file | cut -f3 )

echo $list

mkdir -p $results_folder
cd $results_folder

pwd

mkdir -p count_matrices
mkdir -p sra_files
mkdir -p fastq_files
mkdir -p trim_data
mkdir -p bam
mkdir -p fastp_reports
mkdir -p count_summaries

for exp in ${list[@]}
do
cd count_matrices
num_conteos=$( ls | grep "$exp" | wc -l)
cd ..
if [[ $num_conteos -eq 0 ]]
then
cd sra_files
echo "Starting from next Run:"
echo $exp
prefetch "$exp" --verify yes --check-all
mv "$exp"/* .
rmdir "$exp"
cd ..
output1=$exp"_1_trim.fq.gz"
output2=$exp"_2_trim.fq.gz"
salida_STAR="sorted_"$exp".bam"
matrix=$exp"_matrix_counts"
echo "Performing fastq-dump..."
fastq-dump -I --split-files sra_files/"$exp".sra -O fastq_files/"$exp"
cd fastq_files
mv "$exp"/* .
rmdir "$exp"
num_fastq=$( ls | grep "$exp" | wc -l)
cd ..
if [[ $num_fastq -eq 1 ]]
then
	echo "single-end"
	echo "Number of fastq files:"
	echo "$num_fastq"
	cd fastp_reports
	fastp -j "$exp"_fastp.json -h "$exp"_fastp.html -w 16 --n_base_limit 5 cut_front_window_size 1 cut_front_mean_quality 30 --cut_front cut_tail_window_size 1 cut_tail_mean_quality 30 --cut_tail -l 20 -i "$results_folder"fastq_files/"$exp"_1.fastq -o "$results_folder"trim_data/"$output1"
	cd ..
	echo "Aligning with STAR..."
	cd bam
	STAR --runMode alignReads --genomeDir "$genome_folder""$v_genome"_index --runThreadN 20 --readFilesCommand zcat --readFilesIn "$results_folder"trim_data/"$output1" --outSAMunmapped Within --outSAMtype BAM Unsorted
	cd ..
else
	echo "paired-end"
	echo "Number of fastq files:"
	echo "$num_fastq"
	cd fastp_reports
	fastp -j "$exp"_fastp.json -h "$exp"_fastp.html -w 16 --detect_adapter_for_pe --n_base_limit 5 cut_front_window_size 1 cut_front_mean_quality 30 --cut_front cut_tail_window_size 1 cut_tail_mean_quality 30 --cut_tail -l 20 -i "$results_folder"fastq_files/"$exp"_1.fastq -I "$results_folder"fastq_files/"$exp"_2.fastq -o "$results_folder"trim_data/"$output1" -O "$results_folder"trim_data/"$output2"
	cd ..
	echo "Aligning with STAR..."
	cd bam
	STAR --runMode alignReads --genomeDir "$genome_folder""$v_genome"_index --runThreadN 20 --readFilesCommand zcat --readFilesIn "$results_folder"trim_data/"$output1" "$results_folder"trim_data/"$output2" --outSAMunmapped Within --outSAMtype BAM Unsorted
	cd ..
fi
cd bam
samtools sort -@ 20 Aligned.out.bam -o "$salida_STAR"
cd ..
echo 'Raw counts matrix with featureCounts...'
featureCounts -p -T 20 -t "gene" --minOverlap 1 -C -a "$genome_folder""$v_anotacion".gtf -o count_matrices/"$matrix".txt bam/"$salida_STAR"
mv count_matrices/"$matrix".txt.summary count_summaries/"$matrix".summary
rm sra_files/*
rm fastq_files/"$exp"*
rm trim_data/"$exp"*
cd bam
rm Aligned.out.bam
rm Log*
rm SJ.out.tab
rm sorted_"$exp"*
cd ..
fi
done

#extracting the info from the FeatureCounts summaries files - This feature has been deactivated

#python3 "$scripts_folder"feature_counts_info.py -p "$results_folder"count_summaries
