#######################################################################################
##                                                                                   ##
##                      ____        _                                                ##
##     _____  _____ ___|  _ \ _ __ | |_                                              ##
##    / _ \ \/ / __/ _ \ |_) | '_ \| __|                                             ##
##   |  __/>  < (_|  __/  _ <| |_) | |_                                              ##
##    \___/_/\_\___\___|_| \_\ .__/ \__|                                             ##
##                           |_|                                                     ##
##                                                                                   ##
##                                                                                   ##
## SmallRNA-seq pipeline - processes a single sequence file from a single sample     ##
##                                                                                   ##
## Author: Rob Kitchen (rob.kitchen@yale.edu)                                        ##
##                                                                                   ##
## Version 2.2.9 (2015-12-08)                                                        ##
##                                                                                   ##
#######################################################################################
EXCERPT_VERSION := 2.2.9


##
## 1) On the command line, be sure to specify the following MANDATORY parameters
##
DATA_DIR                := NULL
OUTPUT_DIR              := NULL
INPUT_FILE_PATH         := NULL
SAMPLE_NAME             := NULL
## You can also override the following OPTIONAL parameters on the commandline
CALIBRATOR_LIBRARY      := NULL


##
## 2) Choose the main organism for smallRNA / genome alignment (hsa + hg19, hsa + hg38, or mmu + mm10)
##
## Human:
MAIN_ORGANISM           := hsa
MAIN_ORGANISM_GENOME_ID := hg38
## Mouse:
#MAIN_ORGANISM           := mmu
#MAIN_ORGANISM_GENOME_ID := mm10


##
## 3) Select whether pipeline is run locally, should be 'true' unless this is the Genboree implementation!
##
LOCAL_EXECUTION := true


##
## 4) Choose optional analysis-specific options (or specify these at the command line)
##
ADAPTER_SEQ                     := NULL
TRNA_MAPPING                    := on
PIRNA_MAPPING                   := on
GENCODE_MAPPING                 := on
#REPETITIVE_ELEMENT_MAPPING      := on
CIRCULAR_RNA_MAPPING            := on
REMOVE_LARGE_INTERMEDIATE_FILES := false

QFILTER_MIN_READ_FRAC           := 80
QFILTER_MIN_QUAL                := 20


##
## 5) Choose what kind of EXOGENOUS alignments to attempt 
## 		- off 		: none
##		- miRNAs	: map only to exogenous miRNAs in miRbase
##		- on		: map to exogenous miRNAs in miRbase AND the genomes of all sequenced species in ensembl/NCBI
#MAP_EXOGENOUS      := off
#MAP_EXOGENOUS      := miRNA
MAP_EXOGENOUS      := on


##
## For sample quality control (QC)
##
MIN_TRANSCRIPTOME_MAPPED := 100000
MIN_GENOME_TRANSCRIPTOME_RATIO := 0.5


##
### If this is a local installation of the pipeline, be sure to also modify the parameters in steps 4, 5, and 6 below...
##
ifeq ($(LOCAL_EXECUTION),true)

	##
	## 5) Modify installation-specific variables
	##
	N_THREADS := 4
	JAVA_RAM  := 64G
	MAX_RAM   := 64000000000
	## NB: The 'EXE_DIR' MUST be an ABSOLUTE PATH or sRNABench will fail!
	EXE_DIR   := /gpfs/scratch/fas/gerstein/rrk24/bin/smallRNAPipeline
	
	
	##
	## 6) Check that the paths to the required 3rd party executables work!
	##
	JAVA_EXE         := /usr/bin/java
	FASTX_CLIP_EXE   := $(EXE_DIR)/fastx_0.0.14/bin/fastx_clipper
	FASTX_FILTER_EXE := $(EXE_DIR)/fastx_0.0.14/bin/fastq_quality_filter
	BOWTIE1_PATH    := $(EXE_DIR)/bowtie-1.1.1/bowtie
	#VIENNA_PATH     := $(EXE_DIR)/ViennaRNA_2.1.5/bin
	BOWTIE_EXE       := $(EXE_DIR)/bowtie2-2.2.4/bowtie2
	#SAMTOOLS_EXE     := $(EXE_DIR)/samtools-0.1.18/samtools
	SAMTOOLS_EXE     := $(EXE_DIR)/samtools-1.1/samtools
	FASTQC_EXE       := $(JAVA_EXE) -classpath $(EXE_DIR)/FastQC_0.11.2:$(EXE_DIR)/FastQC_0.11.2/sam-1.103.jar:$(EXE_DIR)/FastQC_0.11.2/jbzip2-0.9.jar
	#SRATOOLS_EXE     := $(EXE_DIR)/sratoolkit.2.1.7-centos_linux64/fastq-dump
	SRATOOLS_EXE     := $(EXE_DIR)/sratoolkit.2.5.1-centos_linux64/bin/fastq-dump
	THUNDER_EXE      := $(EXE_DIR)/Thunder.jar
	SRNABENCH_EXE    := $(EXE_DIR)/sRNAbench.jar
	SRNABENCH_LIBS   := $(EXE_DIR)/sRNAbenchDB
	DATABASE_PATH    := $(EXE_DIR)/DATABASE
	STAR_EXE         := $(EXE_DIR)/STAR_2.4.0i/bin/Linux_x86_64/STAR
	STAR_GENOMES_DIR := /gpfs/scratch/fas/gerstein/rrk24/ANNOTATIONS/Genomes_BacteriaFungiMammalPlantProtistVirus
	
	##
	## Use the input path to infer filetype and short name
	##
	INPUT_FILE_NAME := $(notdir $(INPUT_FILE_PATH))
	INPUT_FILE_ID   := $(basename $(INPUT_FILE_NAME))
	
else
	##
	## These parameters are for the Genboree installation only
	##
	EXE_DIR := $(SCRATCH_DIR)
	N_THREADS := $(N_THREADS)
	JAVA_RAM := 64G
	MAX_RAM  := 64000000000

	FASTX_CLIP_EXE := fastx_clipper
	FASTX_FILTER_EXE := fastq_quality_filter
	BOWTIE1_PATH := NULL
	VIENNA_PATH := NULL
	BOWTIE_EXE := bowtie2
	SAMTOOLS_EXE := samtools
	#FASTQC_EXE := $(JAVA_EXE) -classpath fastqc
	FASTQC_EXE := $(JAVA_EXE) -classpath $(FASTQC_EXE_DIR):$(FASTQC_EXE_DIR)/sam-1.103.jar:$(FASTQC_EXE_DIR)/jbzip2-0.9.jar
	SRATOOLS_EXE := fastq-dump
	SRNABENCH_EXE := $(SRNABENCH_EXE)
	THUNDER_EXE := $(THUNDER_EXE)
	
	## Path to sRNABench libraries
	SRNABENCH_LIBS := $(SRNABENCH_LIBS)

	STAR_EXE := STAR
	STAR_GENOMES_DIR := $(STAR_GENOMES_DIR)
	
	INPUT_FILE_NAME := $(notdir $(INPUT_FILE_PATH))
    INPUT_FILE_ID := $(INPUT_FILE_ID)
endif



## Define current time
ts := `/bin/date "+%Y-%m-%d--%H:%M:%S"`

##
## Initialise organism specific smallRNA library parameters
##
## override format: #<N_mismatches>#<seed_length>#<alignMode [v|n]>#<N_multimaps>
MISMATCH_N_MIRNA := 1
MISMATCH_N_OTHER := 2
MULTIMAP_MAX     := 10000
BOWTIE_OVERRIDE  := \#$(MISMATCH_N_OTHER)\#9\#v\#$(MULTIMAP_MAX)

ifeq ($(MAIN_ORGANISM),hsa)  ## FOR HUMAN
	
	## Override the genome for adapter identification (saves having bt2 indexes for both hg19 and hg38)
	GENOME_ID_FOR_ADAPTER := hg19
	INDEX_TRNA			  := hg19_tRNAs
	INDEX_CIRCULARRNA	  := hg19_CircularRNAs
	

	ifeq ($(MAIN_ORGANISM_GENOME_ID),hg19) ## hg19

		INDEX_GENCODE 		:= hg19_gencode
		INDEX_PIRNA	 		:= hg19_piRNAs
		#INDEX_REP           := hg19_RepetitiveElements
		INDEX_REP           := $(SRNABENCH_LIBS)/customIndices/hg19_repetitiveElements
		BOWTIE_INDEX_RRNA	:= $(SRNABENCH_LIBS)/customIndices/hg19_rRNA
		
	else ifeq ($(MAIN_ORGANISM_GENOME_ID),hg38) ## hg38
		
		INDEX_GENCODE 		:= hg38_gencode
		INDEX_PIRNA	 		:= hg19_piRNAs
		#INDEX_REP           := hg38_RepetitiveElements
		INDEX_REP           := $(SRNABENCH_LIBS)/customIndices/hg38_repetitiveElements
		BOWTIE_INDEX_RRNA	:= $(SRNABENCH_LIBS)/customIndices/hg38_rRNA
		
	endif

else ifeq ($(MAIN_ORGANISM),mmu)  ## FOR MOUSE
	
	GENOME_ID_FOR_ADAPTER := mm10

	INDEX_GENCODE 		:= mm10_gencode
	INDEX_TRNA			:= mm10_tRNAs
	INDEX_PIRNA	 		:= mm10_piRNAs
	#INDEX_REP           := mm10_RepetitiveElements
	INDEX_REP           := $(SRNABENCH_LIBS)/customIndices/mm10_repetitiveElements
	INDEX_CIRCULARRNA	:= mm10_CircularRNAs
	BOWTIE_INDEX_RRNA	:= $(SRNABENCH_LIBS)/customIndices/mm10_rRNA
	
endif

GENCODE_LIBS := libs=$(INDEX_GENCODE)$(BOWTIE_OVERRIDE)
TRNA_LIBS    := libs=$(INDEX_TRNA)$(BOWTIE_OVERRIDE) tRNA=$(INDEX_TRNA) 
PIRNA_LIBS   := libs=$(INDEX_PIRNA)$(BOWTIE_OVERRIDE)
#REP_LIBS     := libs=$(INDEX_REP)$(BOWTIE_OVERRIDE)
REP_LIBS     := $(INDEX_REP)
CIRC_LIBS    := libs=$(INDEX_CIRCULARRNA)$(BOWTIE_OVERRIDE)


##
## Turn off a smallRNA library if they are not selected by the user
##
ifneq ($(TRNA_MAPPING),on)
	TRNA_LIBS    :=
	INDEX_TRNA   :=
endif
ifneq ($(PIRNA_MAPPING),on)
	PIRNA_LIBS   :=
endif
ifneq ($(GENCODE_MAPPING),on)
	GENCODE_LIBS :=
endif
#ifneq ($(REPETITIVE_ELEMENT_MAPPING),on)
#	REP_LIBS     :=
#endif
ifneq ($(CIRCULAR_RNA_MAPPING),on)
	CIRC_LIBS    :=
endif

## SmallRNA sequence libraries to map against AFTER mapping to the known miRNAs for the target organism (see below)
OTHER_LIBRARIES := $(PIRNA_LIBS) $(GENCODE_LIBS) $(CIRC_LIBS) $(TRNA_LIBS) 




USEAGE := 
ifeq ($(INPUT_FILE_ID),NULL)
  USEAGE := "make -f smallRNA_pipeline INPUT_FILE_PATH=[required: absolute/path/to/input/.fa|.fq|.sra] N_THREADS=[required: number of threads] OUTPUT_DIR=<required: absolute/path/to/output> INPUT_FILE_ID=[required: samplename] ADAPTER_SEQ=[optional: will guess sequence if not provided here; none, if already clipped input] MAIN_ORGANISM=[optional: defaults to 'hsa'] MAIN_ORGANISM_GENOME_ID=[optional: defaults to 'hg38'] CALIBRATOR_LIBRARY=[optional: path/to/bowtie/index/containing/calibrator/sequences] TRNA_MAPPING=[optional: TRUE|FALSE, default is TRUE] GENCODE_MAPPING=[optional: TRUE|FALSE, default is TRUE] PIRNA_MAPPING=[optional: TRUE|FALSE, default is TRUE] MAP_EXOGENOUS=[optional: off|miRNA|on, default is miRNA]"
endif



##
## Try to export the Bowtie1 and ViennaRNA executable directories to the PATH
##
EXPORT_CMD :=
ifneq ($(BOWTIE1_EXE),NULL)
	EXPORT_CMD := export PATH=$$PATH:$(BOWTIE1_PATH):$(VIENNA_PATH)
endif


## Path to genome bowtie1 and bowtie2 index
BOWTIE_INDEX_GENOME := $(SRNABENCH_LIBS)/index/$(GENOME_ID_FOR_ADAPTER)


## Path to the UniVec contaminants DB
BOWTIE_INDEX_UNIVEC := $(SRNABENCH_LIBS)/customIndices/UniVec_Core.contaminants



##
## Map reads to plant and virus miRNAs
##
ifeq ($(MAP_EXOGENOUS),miRNA)		## ALIGNMENT TO ONLY EXOGENOUS MIRNA
	PROCESS_SAMPLE_REQFILE := EXOGENOUS_miRNA/reads.fa
else ifeq ($(MAP_EXOGENOUS),on)	## COMPLETE EXOGENOUS GENOME ALIGNMENT
	PROCESS_SAMPLE_REQFILE := EXOGENOUS_genomes/ExogenousGenomicAlignments.result.txt
else
	PROCESS_SAMPLE_REQFILE := noGenome/reads.fa
endif


##
## List of plant and virus species IDs to which to map reads that do not map to the genome of the primary organism
##
EXOGENOUS_MIRNA_SPECIES := $(shell cat $(SRNABENCH_LIBS)/libs/mature.fa | grep ">" | awk -F '-' '{print $$1}' | sed 's/>//g'| sort | uniq | tr '\n' ':' | rev | cut -c 2- | rev | sed 's/$(MAIN_ORGANISM)://g')

## Parameters to use for the bowtie mapping of calibrator oligos and rRNAs
BOWTIE2_MAPPING_PARAMS_CALIBRATOR := -D 15 -R 2 -N 1 -L 16 -i S,1,0
BOWTIE2_MAPPING_PARAMS_RRNA       := -D 15 -R 2 -N 1 -L 19 -i S,1,0

#################################################





##
## Generate unique ID from the input fastq filename and user's sample ID
##
SAMPLE_ID := $(INPUT_FILE_ID)
ifneq ($(SAMPLE_NAME),NULL)
  SAMPLE_ID := $(SAMPLE_ID)_$(SAMPLE_NAME)
endif



##
## Detect filetype and extract from SRA format if necessary
##
COMMAND_CONVERT_SRA := cat $(INPUT_FILE_PATH)
ifeq ($(suffix $(INPUT_FILE_NAME)),.sra)
	COMMAND_CONVERT_SRA := $(SRATOOLS_EXE) --stdout $(INPUT_FILE_PATH)
else ifeq ($(suffix $(INPUT_FILE_NAME)),.gz)
	COMMAND_CONVERT_SRA := gunzip -c $(INPUT_FILE_PATH)
endif


##
## Guess quality encoding
##
#COMMAND_FILTER_BY_QUALITY ?= gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz | $(FASTX_FILTER_EXE) -v -Q$(shell cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).qualityEncoding) -p $(QFILTER_MIN_READ_FRAC) -q $(QFILTER_MIN_QUAL) > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.tmp 2>>$(OUTPUT_DIR)/$(SAMPLE_ID).log


##
## Logic block to write the adapter sequence (whether or not one is provided by the user) to the .adapterSeq file
##
ifeq ($(ADAPTER_SEQ),NULL)
	COMMAND_WRITE_ADAPTER_SEQ := $(COMMAND_CONVERT_SRA) 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | head -n 40000000 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | $(BOWTIE_EXE) --no-head -p $(N_THREADS) --local -D 15 -R 2 -N 0 -L 20 -i S,1,0.75 -k 2 --upto 10000000 -x $(BOWTIE_INDEX_GENOME) -U - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '{if ($$5==255) print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.unique.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log;  \
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.unique.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{print $$6}' 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort -rnk 1 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | head -n 100 > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).cigarFreqs 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err;  \
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.unique.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{if ($$2==0) print $$3"\t"$$4"\t"$$6"\t"$$10}' 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | grep "[[:space:]]2[0-9]M[0-9][0-9]S" > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err;  \
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{print $$3}' 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort -rnk 1 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | head -n 100 > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).okCigarFreqs 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err;  \
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).okCigarFreqs 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | head -n 1 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{print substr($$2,1,2)}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.txt 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err;  \
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | grep "[[:space:]]$$(<$(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.txt)" 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{getline len<"$(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.txt"; print substr($$4,len+1)}' 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sed 's/[A]*$$//' 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | sort -rnk 1 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | awk '{if ($$1 > 75) print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).potentialAdapters.txt 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err;  \
	head -n 1 $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).potentialAdapters.txt | awk '{print $$2}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).adapterSeq;  \
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.*
	LOGENTRY_WRITE_ADAPTER := $(ts) SMRNAPIPELINE: Removing 3' adapter sequence using fastX:\n
else ifeq ($(ADAPTER_SEQ),none)
	COMMAND_WRITE_ADAPTER_SEQ := echo 'no adapter' > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).adapterSeq;
	COMMAND_CLIP_ADAPTER := $(COMMAND_CONVERT_SRA) | gzip -c > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	LOGENTRY_WRITE_ADAPTER := Provided 3' adapter clipped input sequence file. No clipping necessary.\n 
else
	COMMAND_WRITE_ADAPTER_SEQ := echo $(ADAPTER_SEQ) > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).adapterSeq
	LOGENTRY_WRITE_ADAPTER := $(ts) SMRNAPIPELINE: Provided 3' adapter sequence. Removing 3' adapter sequence using fastX:\n
endif


## If no adapter clipping command has been set- use this one:
COMMAND_CLIP_ADAPTER ?= $(COMMAND_CONVERT_SRA) | $(FASTX_CLIP_EXE) -a $(shell cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).adapterSeq) -l 10 -v -M 7 -z -o $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err




##
## Logic block for removing rRNAs and [optionally] calibrator sequences that may have been spiked into the sample
##
ifeq ($(CALIBRATOR_LIBRARY),NULL)
	
	LOGENTRY_MAP_CALIBRATOR_1 := No calibrator sequences\n 
	LOGENTRY_MAP_CALIBRATOR_2 := Moving on to UniVec and rRNA sequences\n
	COMMAND_COUNT_CALIBRATOR := echo -e "calibrator\tNA" >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	COMMAND_MAP_CALIBRATOR := 
	
	FILE_TO_INPUT_TO_UNIVEC_ALIGNMENT := $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz
	
else
	
	COMMAND_COUNT_CALIBRATOR := cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.calibratormapped.counts | awk '{sum+=$$1} END {print "calibrator\t"sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	COMMAND_MAP_CALIBRATOR := $(BOWTIE_EXE) -p $(N_THREADS) $(BOWTIE2_MAPPING_PARAMS_CALIBRATOR) --un-gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noCalibrator.fastq.gz -x $(CALIBRATOR_LIBRARY) -U $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '$$2 != 4 {print $$0}' | $(SAMTOOLS_EXE) view -Sb - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | tee $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.calibratormapped.bam | $(SAMTOOLS_EXE) view - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '{print $$3}' | sort -k 2 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq --count > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.calibratormapped.counts 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	LOGENTRY_MAP_CALIBRATOR_1 := $(ts) SMRNAPIPELINE: Mapping reads to calibrator sequences using bowtie:\n
	LOGENTRY_MAP_CALIBRATOR_2 := $(ts) SMRNAPIPELINE: Finished mapping to the calibrators\n
	
	FILE_TO_INPUT_TO_UNIVEC_ALIGNMENT := $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noCalibrator.fastq.gz
	
endif


##
## Bowtie2 command to align reads to the UniVec contaminant sequence database
##
COMMAND_MAP_UNIVEC := $(BOWTIE_EXE) -p $(N_THREADS) $(BOWTIE2_MAPPING_PARAMS_RRNA) --un-gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noUniVecContaminants.fastq.gz -x $(BOWTIE_INDEX_UNIVEC) -U $(FILE_TO_INPUT_TO_UNIVEC_ALIGNMENT) 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '$$2 != 4 {print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.sam; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.sam | grep -v "^@" | awk '{print $$3}' | sort -k 2 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq --count > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminants.counts 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.sam | grep -v "^@" | awk '{print $$1}' | sort 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c | wc -l > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminants.readCount 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.sam | $(SAMTOOLS_EXE) view -Sb - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.bam; \
rm $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminantMapped.sam


##
## Bowtie2 command to align reads to the rRNA sequences
##
COMMAND_MAP_RRNAS := $(BOWTIE_EXE) -p $(N_THREADS) $(BOWTIE2_MAPPING_PARAMS_RRNA) --un-gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz -x $(BOWTIE_INDEX_RRNA) -U $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noUniVecContaminants.fastq.gz 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '$$2 != 4 {print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sam; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sam | grep -v "^@" | awk '{print $$3}' | sort -k 2 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNA.counts 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sam | grep -v "^@" | awk '{print $$1}' | sort 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err | uniq -c | wc -l > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNA.readCount 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err; \
cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sam | $(SAMTOOLS_EXE) view -Sb - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.bam; \
rm $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sam



## Parameters for the endogenous-exRNA mapping
FIXED_PARAMS_MAIN      := -Xmx$(JAVA_RAM) -jar $(SRNABENCH_EXE) dbPath=$(SRNABENCH_LIBS) p=$(N_THREADS) chunkmbs=2000 microRNA=$(MAIN_ORGANISM) species=$(MAIN_ORGANISM_GENOME_ID) plotMiR=true plotLibs=false predict=false $(OTHER_LIBRARIES) writeGenomeDist=true noMM=$(MISMATCH_N_MIRNA) maxReadLength=75 noGenome=true mBowtie=$(MULTIMAP_MAX)
## Parameters for the exogenous-exRNA mapping
FIXED_PARAMS_EXOGENOUS := -Xmx$(JAVA_RAM) -jar $(SRNABENCH_EXE) dbPath=$(SRNABENCH_LIBS) p=$(N_THREADS) chunkmbs=2000 microRNA=$(EXOGENOUS_MIRNA_SPECIES) plotMiR=true predict=false noMM=$(MISMATCH_N_MIRNA)


##
## Remove some potentially large intermediate pipeline output (can save as much as 50% total output size)
##
TIDYUP_COMMAND := 
ifeq ($(REMOVE_LARGE_INTERMEDIATE_FILES),true)
	TIDYUP_COMMAND := rm $(OUTPUT_DIR)/$(SAMPLE_ID)/genome.parsed; rm $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped*.fastq.gz
endif


##
## Compress only the most vital output!
##
COMPRESS_COMMAND := ls -lh $(OUTPUT_DIR)/$(SAMPLE_ID) | awk '{print $$9}' | grep "sense.grouped\|.readLengths.txt\|_fastqc.zip\|stat\|.counts\|.adapterSeq\|.qualityEncoding" | awk '{print "$(SAMPLE_ID)/"$$1}' > $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt; \
ls -lh $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome | awk '{print $$9}' | grep "sense.grouped\|stat" | awk '{print "$(SAMPLE_ID)/noGenome/"$$1}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt; \
echo $(SAMPLE_ID).log >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt; \
echo $(SAMPLE_ID).qcResult >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt; \
echo $(SAMPLE_ID).stats >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt
ifneq ($(CALIBRATOR_LIBRARY),NULL)
	COMPRESS_COMMAND := $(COMPRESS_COMMAND); echo $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.calibratormapped.counts >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt
endif
ifneq ($(wildcard $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/.),)
	COMPRESS_COMMAND := $(COMPRESS_COMMAND); ls -lh $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA | awk '{print $$9}' | grep "sense.grouped" | awk '{print "$(SAMPLE_ID)/EXOGENOUS_miRNA/"$$1}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt
endif
ifneq ($(wildcard $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/.),)
	COMPRESS_COMMAND := $(COMPRESS_COMMAND); ls -lh $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes | awk '{print $$9}' | grep "ExogenousGenomicAlignments.sorted.txt\|ExogenousGenomicAlignments.result.txt" | awk '{print "$(SAMPLE_ID)/EXOGENOUS_genomes/"$$1}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt
endif



###########################################################
###########################################################
###########################################################

##
## Main make target
##
.PHONY: all
.DEFAULT: all
all: processSample


##
## Target to selectively compress only the most useful results for downstream processing
##
## - this will typically reduce the volume of data needing to be transferred by 100x
##
compressCoreResults:
	$(COMPRESS_COMMAND)
	tar -cvz -C $(OUTPUT_DIR) -T $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt -f $(OUTPUT_DIR)/$(SAMPLE_ID)_results.tgz
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)_filesToCompress.txt


##
## Delete sample results and logfiles
##
#clean: 
#	rm -r $(OUTPUT_DIR)/$(SAMPLE_ID)




##
###
####  BEGIN PIPELINE
####
####  vvv Sub-targets to do the read-preprocessing, calibrator mapping, rRNA mapping, en-exRNA mapping, and ex-exRNA mapping vvv
###
##


##
## Make results directory & Write adapter sequence
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/Progress_1_FoundAdapter.dat: 
	#$(EXPORT_CMD)
	@echo -e "$(USEAGE)"
	mkdir -p $(OUTPUT_DIR)/$(SAMPLE_ID)
	@echo -e "$(ts) SMRNAPIPELINE: BEGIN exceRpt smallRNA-seq pipeline v.$(EXCERPT_VERSION) for sample $(SAMPLE_ID)\n======================\n" > $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: BEGIN \n" > $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: Created results dir: $(OUTPUT_DIR)/$(SAMPLE_ID)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Processing adapter sequence:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_WRITE_ADAPTER_SEQ)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	$(COMMAND_WRITE_ADAPTER_SEQ)
	@echo -e "$(ts) SMRNAPIPELINE: Progress_1_FoundAdapter" > $(OUTPUT_DIR)/$(SAMPLE_ID)/Progress_1_FoundAdapter.dat
	#
	@echo -e "#STATS from the exceRpt smallRNA-seq pipeline v.$(EXCERPT_VERSION) for sample $(SAMPLE_ID)" > $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	@echo -e "Stage\tReadCount" >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
## CLIP 3' adapter sequence
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz: $(OUTPUT_DIR)/$(SAMPLE_ID)/Progress_1_FoundAdapter.dat
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Adapter sequence: $(shell cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).adapterSeq)" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(LOGENTRY_WRITE_ADAPTER)" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_CLIP_ADAPTER)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	$(COMMAND_CLIP_ADAPTER)
	@echo -e "$(ts) SMRNAPIPELINE: Finished removing adapters\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count reads input to adapter clipping
	grep "Input: " $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '{print "input\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Count reads output following adapter clipping
	grep "Output: " $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '{print "successfully_clipped\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
## Guess Fastq quality encoding
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).qualityEncoding: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Guessing encoding of fastq read-qualities:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_CONVERT_SRA) | head -n 40000 | awk '{if(NR%4==0) printf("%s",$$0);}' | od -A n -t u1 | awk 'BEGIN{min=100;max=0;}{for(i=1;i<=NF;i++) {if($$i>max) max=$$i; if($$i<min) min=$$i;}}END{if(max<=74 && min<59) print "33"; else if(max>73 && min>=64) print "64"; else if(min>=59 && min<64 && max>73) print "64"; else print "64";}' > $@\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#$(COMMAND_CONVERT_SRA) | head -n 40000 | awk '{if(NR%4==0) printf("%s",$$0);}' | od -A n -t u1 | awk 'BEGIN{min=100;max=0;}{for(i=1;i<=NF;i++) {if($$i>max) max=$$i; if($$i<min) min=$$i;}}END{if(max<=74 && min<59) print "33"; else if(max>73 && min>=64) print "64"; else if(min>=59 && min<64 && max>73) print "64"; else print "64";}' > $@
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_CONVERT_SRA) | head -n 40000 | awk '{if(NR%4==0) printf("%s",$$0);}' | od -A n -t u1 | awk 'BEGIN{min=100;max=0;}{for(i=1;i<=NF;i++) {if($$i>max) max=$$i; if($$i<min) min=$$i;}}END{if(max<=74) print "33"; else if(max>74 && min>=64) print "64"; else if(min>=59 && min<64 && max>73) print "64"; else print "64";}' > $@\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(COMMAND_CONVERT_SRA) | head -n 40000 | awk '{if(NR%4==0) printf("%s",$$0);}' | od -A n -t u1 | awk 'BEGIN{min=100;max=0;}{for(i=1;i<=NF;i++) {if($$i>max) max=$$i; if($$i<min) min=$$i;}}END{if(max<=74) print "33"; else if(max>74 && min>=64) print "64"; else if(min>=59 && min<64 && max>73) print "64"; else print "64";}' > $@
	@echo -e "$(ts) SMRNAPIPELINE: Finished guessing encoding of fastq read-qualities:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log


##
## FILTER clipped reads that have poor overall base quality  &  Remove homopolymer repeats
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).qualityEncoding
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Filtering reads by base quality:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_FILTER_BY_QUALITY)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	#$(COMMAND_FILTER_BY_QUALITY)
	@echo -e "$(ts) SMRNAPIPELINE: gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz | $(FASTX_FILTER_EXE) -v -Q$(shell cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).qualityEncoding) -p $(QFILTER_MIN_READ_FRAC) -q $(QFILTER_MIN_QUAL) > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.tmp\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.fastq.gz | $(FASTX_FILTER_EXE) -v -Q$(shell cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).qualityEncoding) -p $(QFILTER_MIN_READ_FRAC) -q $(QFILTER_MIN_QUAL) > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.tmp 2>>$(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Finished filtering reads by base quality\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count reads that failed the quality filter
	grep "low-quality reads" $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '{print "failed_quality_filter\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	# Filter homopolymer reads (those that have too many single nt repeats)
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Filtering homopolymer repeat reads:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(JAVA_EXE) -Xmx$(JAVA_RAM) -jar $(THUNDER_EXE) RemoveHomopolymerRepeats -m 0.66 -i $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.tmp -o $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	$(JAVA_EXE) -Xmx$(JAVA_RAM) -jar $(THUNDER_EXE) RemoveHomopolymerRepeats --verbose -m 0.66 -i $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.tmp -o $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.REMOVEDRepeatReads.fastq
	gzip $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq
	@echo -e "$(ts) SMRNAPIPELINE: Finished filtering homopolymer repeat reads\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count homopolymer repeat reads that failed the quality filter
	grep "Done.  Sequences removed" $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk -F "=" '{print "failed_homopolymer_filter\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
## Assess Read-lengths after clipping
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.readLengths.txt: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz
	@echo -e "======================" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Calculating length distribution of clipped reads:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(JAVA_EXE) -Xmx$(JAVA_RAM) -jar $(THUNDER_EXE) GetSequenceLengths $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq > $@ 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $< > $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq
	$(JAVA_EXE) -Xmx$(JAVA_RAM) -jar $(THUNDER_EXE) GetSequenceLengths $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq > $@ 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq
	@echo -e "$(ts) SMRNAPIPELINE: Finished calculating read-lengths\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log


##
## Perform FastQC after adapter removal
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered_fastqc.zip: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz
	@echo -e "======================" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Running FastQC on clipped reads:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(FASTQC_EXE) -Xmx$(JAVA_RAM) -Dfastqc.threads=$(N_THREADS) -Dfastqc.unzip=false -Dfastqc.output_dir=$(OUTPUT_DIR)/$(SAMPLE_ID)/ uk/ac/bbsrc/babraham/FastQC/FastQCApplication $< >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(FASTQC_EXE) -Xmx$(JAVA_RAM) -Dfastqc.threads=$(N_THREADS) -Dfastqc.unzip=false -Dfastqc.output_dir=$(OUTPUT_DIR)/$(SAMPLE_ID)/ uk/ac/babraham/FastQC/FastQCApplication $< >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: Finished running FastQC\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log


##
## MAP to external bowtie (calibrator?) library and to UniVec sequences
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noUniVecContaminants.fastq.gz: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.fastq.gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.readLengths.txt $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered_fastqc.zip
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(LOGENTRY_MAP_CALIBRATOR_1)" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_MAP_CALIBRATOR)" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(COMMAND_MAP_CALIBRATOR)
	@echo -e "$(ts) SMRNAPIPELINE: $(LOGENTRY_MAP_CALIBRATOR_2)" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count calibrator oligo reads
	$(COMMAND_COUNT_CALIBRATOR)
	#
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to contaminant sequences in UniVec using Bowtie2:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_MAP_UNIVEC)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(COMMAND_MAP_UNIVEC)
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to the UniVec contaminant DB\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count UniVec contaminant reads
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.uniVecContaminants.readCount | awk '{print "UniVec_contaminants\t"$$1}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	

##
## MAP to rRNA sequences
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noUniVecContaminants.fastq.gz
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to ribosomal RNA sequences using Bowtie2:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(COMMAND_MAP_RRNAS)\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(COMMAND_MAP_RRNAS) 
	$(SAMTOOLS_EXE) sort $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.bam $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sorted
	$(SAMTOOLS_EXE) index $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.sorted.bam
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNAmapped.bam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to the rRNAs\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count rRNA reads
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.rRNA.readCount | awk ' {print "rRNA\t"$$1}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
## Perform FastQC again after rRNA / UniVec removal
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA_fastqc.zip: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz
	@echo -e "======================" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Running FastQC on cleaned reads:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(FASTQC_EXE) -Xmx$(JAVA_RAM) -Dfastqc.threads=$(N_THREADS) -Dfastqc.unzip=false -Dfastqc.output_dir=$(OUTPUT_DIR)/$(SAMPLE_ID)/ uk/ac/bbsrc/babraham/FastQC/FastQCApplication $< >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(FASTQC_EXE) -Xmx$(JAVA_RAM) -Dfastqc.threads=$(N_THREADS) -Dfastqc.unzip=false -Dfastqc.output_dir=$(OUTPUT_DIR)/$(SAMPLE_ID)/ uk/ac/babraham/FastQC/FastQCApplication $< >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: Finished running FastQC\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log


##
## Map reads to the main genome of interest
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/reads.fa: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA_fastqc.zip
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to smallRNAs of primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(JAVA_EXE) $(FIXED_PARAMS_MAIN) input=$< output=$(OUTPUT_DIR)/$(SAMPLE_ID) >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 
	$(JAVA_EXE) $(FIXED_PARAMS_MAIN) input=$< output=$(OUTPUT_DIR)/$(SAMPLE_ID) >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to the small-RNAs of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#@echo -e "$(ts) SMRNAPIPELINE: grep "chrUn_gl000220" $(OUTPUT_DIR)/$(SAMPLE_ID)/genome.txt | awk '{print $$1}' | sed 's/#/ /g' | awk '{ sum += $$2 } END { print "Number of reads mapped to chrUn_gl000220 = "sum }' >> $(OUTPUT_DIR)/$(SAMPLE_ID).log\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	#grep "chrUn_gl000220" $(OUTPUT_DIR)/$(SAMPLE_ID)/genome.txt | awk '{print $$1}' | sed 's/#/ /g' | awk '{ sum += $$2 } END { print "Number of reads mapped to chrUn_gl000220 = "sum }' >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Count reads not mapped to rRNA
	grep "No. raw input reads:" $(OUTPUT_DIR)/$(SAMPLE_ID).log | head -n 1 | awk -F ':' '{print "reads_used_for_alignment\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Count reads mapped to the genome
	grep "out of" $(OUTPUT_DIR)/$(SAMPLE_ID)/summary.txt | awk '{print "genome\t"$$2}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	## Assigned non-redundantly to annotated miRNAs (sense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/mature_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/mature_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "miRNA_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated miRNAs (antisense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/mature_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/mature_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "miRNA_antisense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	## Assigned non-redundantly to annotated tRNAs (sense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_TRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_TRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "tRNA_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated tRNAs (antisense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_TRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_TRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "tRNA_antisense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	## Assigned non-redundantly to annotated piRNAs (sense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_PIRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_PIRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "piRNA_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated piRNAs (antisense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_PIRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_PIRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "piRNA_antisense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	## Assigned non-redundantly to annotated transcripts in Gencode (sense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_GENCODE)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_GENCODE)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "gencode_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated transcripts in Gencode (antisense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_GENCODE)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_GENCODE)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "gencode_antisense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	#
	## Assigned non-redundantly to annotated circular RNAs (sense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_CIRCULARRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_CIRCULARRNA)_sense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "circularRNA_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated circular RNAs (antisense)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/$(INDEX_CIRCULARRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/$(INDEX_CIRCULARRNA)_antisense.grouped | grep -v "RPM (total)" | awk '{sum+=$$4} END {print sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount | awk '{sum+=$$1} END {printf "circularRNA_antisense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.readcount



##
## Map reads to the endogenous genome and transcriptome
##

## map ALL READS to the GENOME (bowtie 1 ungapped)
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA_fastqc.zip
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to the genome of the primary organism $(MAIN_ORGANISM_GENOME_ID):\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --fullref --best --strata -e 2000 --un endogenousUnaligned_ungapped.fq $(BOWTIE_INDEX_GENOME) - | $(SAMTOOLS_EXE) view -@ $(N_THREADS) -b - | $(SAMTOOLS_EXE) sort -@ $(N_THREADS) -O bam -T tmp - > $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to the genome of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## map ALL READS to the PRECURSORs (bowtie 1 ungapped)
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_miRBase_v21_hairpin_hsa.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to miRNA precursors of the primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --sam-nohead --fullref --best --strata $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/miRBase_v21_hairpin_hsa - | awk -F "\t" '{if($$2 != 4){print $$0}}' > endogenousAlignments_miRBase_v21_hairpin_hsa.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to miRNA precursors of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## map ALL READS to tRNAs
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_tRNA.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to tRNAs of the primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --sam-nohead --fullref --best --strata -e 2000 $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/hg19_tRNAs - | awk -F "\t" '{if($$2 != 4){print $$0}}' > endogenousAlignments_tRNA.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to tRNAs of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## map ALL READS to piRNAs
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_piRNA.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to piRNAs of the primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --sam-nohead --fullref --best --strata -e 2000 $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/hg19_piRNAs - | awk -F "\t" '{if($$2 != 4){print $$0}}' > endogenousAlignments_piRNA.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to piRNAs of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## map ALL READS to circular RNA junctions
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_circRNA.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to circular RNA junctions of the primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --sam-nohead --fullref --best --strata -e 2000 $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/hg19_CircularRNAs - | awk -F "\t" '{if($$2 != 4){print $$0}}' > endogenousAlignments_circRNA.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to circular RNA junctions of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## map ALL READS to gencode transcripts
$(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_gencode.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to all ensembl/gencode transcripts of the primary organism:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	gunzip -c $(OUTPUT_DIR)/$(SAMPLE_ID)/$(SAMPLE_ID).clipped.filtered.noRiboRNA.fastq.gz | $(BOWTIE1_PATH) -p $(N_THREADS) --chunkmbs 2048 -l 19 -n $(MISMATCH_N_MIRNA) --all --sam --sam-nohead --fullref --best --strata -e 2000 $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/hg19_gencode - | awk -F "\t" '{if($$2 != 4){print $$0}}' > endogenousAlignments_gencode.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to all ensembl/gencode transcripts of the primary organism\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

## process alignments
$(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_gencode_sense.txt: $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_miRBase_v21_hairpin_hsa.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_tRNA.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_piRNA.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_circRNA.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_gencode.sam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Processing alignments\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(SAMTOOLS_EXE) view $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam | awk -F "\t" '{print $$1"\t"$$2"\tunannotated:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_miRBase_v21_hairpin_hsa.sam | awk -F "\t" '{print $$1"\t"$$2"\tmiRNA:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_tRNA.sam | awk -F "\t" '{print $$1"\t"$$2"\ttRNA:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_piRNA.sam | awk -F "\t" '{print $$1"\t"$$2"\tpiRNA:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_gencode.sam | awk -F "\t" '{print $$1"\t"$$2"\tgencode:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14"\t"$$15}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_circRNA.sam | awk -F "\t" '{print $$1"\t"$$2"\tcircRNA:"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam | sort -k 1,3 | sed 's/ /:/g' > $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_ALL.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished processing alignments\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	
	@echo -e "$(ts) SMRNAPIPELINE: Assigning reads\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	java -Xmx10G -jar ~/bin/Thunder.jar ProcessEndogenousAlignments --hairpin2genome $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/miRBase_v21_hairpin_hsa_hg19_aligned.sam --mature2hairpin $(DATABASE_PATH)/$(MAIN_ORGANISM_GENOME_ID)/miRBase_v21_mature_hairpin_hsa_aligned.sam --reads2all $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_ALL.sam --outputPath $(OUTPUT_DIR)/$(SAMPLE_ID)
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/mature_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_miRNAmature_sense.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/hairpin_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_miRNAprecursor_sense.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/tRNA_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_tRNA_sense.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/piRNA_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_piRNA_sense.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/circularRNA_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_circularRNA_sense.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/gencode_sense.tmp | sort -nrk 2 > $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_gencode_sense.txt
	@echo -e "$(ts) SMRNAPIPELINE: Finished assigning reads\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log

	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/*.tmp
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/tmp.sam



##
## Align reads to repetitive element sequences, just in case repetitive reads have not been mapped to the genome
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotRepetitive.fa: $(OUTPUT_DIR)/$(SAMPLE_ID)/readCounts_gencode_sense.txt $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousAlignments_unspliced.bam
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to repetitive elements in the host genome:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousUnaligned_ungapped.fq | $(BOWTIE_EXE) -p $(N_THREADS) $(BOWTIE2_MAPPING_PARAMS_RRNA) --un $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fa -x $(REP_LIBS) -U - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '$$2 != 4 {print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/RepeatElementsMapped.sam\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousUnaligned_ungapped.fq | $(BOWTIE_EXE) -p $(N_THREADS) $(BOWTIE2_MAPPING_PARAMS_RRNA) --un $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fa -x $(REP_LIBS) -U - 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).log | awk '$$2 != 4 {print $$0}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/RepeatElementsMapped.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to repetitive elements in the host genome\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Input to RE alignment
	#cat $(OUTPUT_DIR)/$(SAMPLE_ID)/noGenome/reads.fa | grep ">" | awk -F "#" '{sum+=$$2} END {print "input_to_repetitiveElement_alignment\t"sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/endogenousUnaligned_ungapped.fq | grep "@" | awk -F "#" '{sum+=$$2} END {print "input_to_repetitiveElement_alignment\t"sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated REs	
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/RepeatElementsMapped.sam | grep -v "^@" | awk '{print $$1}' | sort | uniq | awk -F "#" '{SUM+=$$2}END{print "repetitiveElements\t"SUM}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats



##
## map REMAINING reads to the genome (bowtie 2 gapped)
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fq.gz: $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotRepetitive.fa
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Aligning remaining reads to the genome allowing gaps \n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotRepetitive.fa | $(BOWTIE_EXE) -p $(N_THREADS) --local -D 20 -R 3 -N 0 -L 19 -i S,1,0.50 --all --reorder --no-head --un-gz $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fq.gz -x /gpfs/scratch/fas/gerstein/rrk24/bin/smallRNAPipeline/sRNAbenchDB/index/hg19 -U - | awk -F "\t" '{if($$2 >= 16){print $$0}}' > endogenousAlignments_gapped.sam
	@echo -e "$(ts) SMRNAPIPELINE: Finished aligning remaining reads to the genome allowing gaps\n” >> $(OUTPUT_DIR)/$(SAMPLE_ID).log



##
## Use the unmapped reads and search against all plant and viral miRNAs in miRBase
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa: $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fq.gz
	@echo -e "======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: Mapping reads to smallRNAs of plants and viruses:\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: $(JAVA_EXE) $(FIXED_PARAMS_EXOGENOUS) input=$(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fa output=$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	$(JAVA_EXE) $(FIXED_PARAMS_EXOGENOUS) input=$(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fa output=$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA >> $(OUTPUT_DIR)/$(SAMPLE_ID).log 2>> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "$(ts) SMRNAPIPELINE: Finished mapping to plant and virus small-RNAs\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	## Input to exogenous miRNA alignment
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/reads_NotEndogenous.fa | grep ">" | awk -F "#" '{sum+=$$2} END {print "input_to_miRNA_exogenous\t"sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Assigned non-redundantly to annotated exogenous miRNAs
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/mature_sense.grouped | awk '{sum+=$$4} END {printf "miRNA_exogenous_sense\t%.0f\n",sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
## NEW routines for aligning unmapped reads to exogenous sequences
##
## Bacteria
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria10_Aligned.out.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa
	mkdir -p $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria1_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA1 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria2_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA2 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria3_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA3 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria4_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA4 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria5_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA5 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria6_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA6 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria7_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA7 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria8_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA8 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria9_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA9 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria10_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_BACTERIA10 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in

## Plants
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants5_Aligned.out.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa
	mkdir -p $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants1_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_PLANTS1 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants2_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_PLANTS2 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants3_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_PLANTS3 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants4_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_PLANTS4 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants5_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_PLANTS5 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in

## Fungi, Protist, and Virus
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_Aligned.out.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa
	mkdir -p $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_FUNGI_PROTIST_VIRUS --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in

## Vertebrates
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate4_Aligned.out.sam: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa
	mkdir -p $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate1_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_VERTEBRATE1 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate2_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_VERTEBRATE2 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate3_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_VERTEBRATE3 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in
	$(STAR_EXE) --runThreadN $(N_THREADS) --outFileNamePrefix $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate4_ --genomeDir $(STAR_GENOMES_DIR)/STAR_GENOME_VERTEBRATE4 --readFilesIn $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa --parametersFiles $(STAR_GENOMES_DIR)/STAR_Parameters_Exogenous.in



##
## Combine exogenous genome alignment info
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.txt: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria10_Aligned.out.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants5_Aligned.out.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_Aligned.out.sam $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate4_Aligned.out.sam
	
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria1_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria2_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria3_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria4_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria5_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria6_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria7_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria8_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria9_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria10_Aligned.out.sam | grep -v "^@" | awk '{print $$1,$$3,$$4,$$6,$$10}' | uniq | sed 's/[:$$]/ /g' | awk '{print $$1"\tBacteria\t"$$2"\t"$$7"\t"$$12"\t"$$13"\t"$$14}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary
	#
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants1_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants2_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants3_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants4_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants5_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary
	#
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_Aligned.out.sam | grep -v "^@" | grep "Virus:" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | sed 's/|/ /g' | awk '{print $$1"\t"$$2"\t"$$4"\t"$$6"\t"$$7"\t"$$8"\t"$$9}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Virus_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_Aligned.out.sam | grep -v "^@" | grep "Fungi:" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Fungi_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/FungiProtistVirus_Aligned.out.sam | grep -v "^@" | grep "Protist:" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Protist_Aligned.out.sam.summary
	#
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate1_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate2_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate3_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate_Aligned.out.sam.summary
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate4_Aligned.out.sam | grep -v "^@" | awk '{print $$1" "$$3" "$$4" "$$6" "$$10}' | uniq | sed 's/:/ /g' | awk '{print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$7}' >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate_Aligned.out.sam.summary
	#
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Bacteria_Aligned.out.sam.summary > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Plants_Aligned.out.sam.summary >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Virus_Aligned.out.sam.summary >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Fungi_Aligned.out.sam.summary >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Protist_Aligned.out.sam.summary >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/Vertebrate_Aligned.out.sam.summary >> $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt
	#
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.txt | sort -k 1 > $@
	#
	## Input to exogenous miRNA alignment
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_miRNA/reads.fa | grep ">" | awk -F "#" '{sum+=$$2} END {print "input_to_exogenous_genomes\t"sum}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats
	## Count reads mapped to exogenous genomes:
	cat $@ | awk '{print $$1}' | uniq | awk -F "#" '{SUM += $$2} END {print "exogenous_genomes\t"SUM}' >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats



##
## Create exogenous alignment result matrix:
##
$(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.result.txt: $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.txt
	# remove duplicate reads that correspond to multimaps within a single species
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.txt | awk '{print $$1"\t"$$2"\t"$$3}' | uniq > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt
	# get the IDs of reads aligning uniquely to one kingdom
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt | awk '{print $$1"\t"$$2}' | uniq | awk '{print $$1}' | uniq -c | awk '{if($$1==1) print $$2}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.kingdomUniqueReads
	# get the IDs of reads aligning uniquely to one species
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt | awk '{print $$1}' | uniq -c | awk '{if($$1==1) print $$2}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.speciesUniqueReads
	#
	## count all reads aligning to each species, regardless of multimapping
	cat $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt | sed 's/#/\t/' | awk '{arr[$$3"\t"$$4]+=$$2} END {for (x in arr) print x"\t"arr[x]}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.counts
	## count only reads aligning to each species that only multi map to the same kingdom
	awk 'NR==FNR {h[$$1]="YES_YES_YES"; next} {print $$1,$$2,$$3,h[$$1]}' $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.kingdomUniqueReads $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt | grep "YES_YES_YES" | awk '{print $$1"\t"$$2"\t"$$3}' | sed 's/#/\t/' | awk '{arr[$$3"\t"$$4]+=$$2} END {for (x in arr) print x"\t"arr[x]}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.kingdom.counts
	awk 'NR==FNR {h[$$1]="YES_YES_YES"; next} {print $$1,$$2,$$3,h[$$1]}' $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.speciesUniqueReads $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.sorted.unique.txt | grep "YES_YES_YES" | awk '{print $$1"\t"$$2"\t"$$3}' | sed 's/#/\t/' | awk '{arr[$$3"\t"$$4]+=$$2} END {for (x in arr) print x"\t"arr[x]}' > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.species.counts
	## combine all counts and kingdom level counts:
	awk 'NR==FNR {h[$$2]=$$3; next} {if($$2 in h) print $$0"\t"h[$$2]; else print $$0"\t0"}' $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.kingdom.counts $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.counts > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp
	awk 'NR==FNR {h[$$2]=$$3; next} {if($$2 in h) print $$0"\t"h[$$2]; else print $$0"\t0"}' $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp.species.counts $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp | sort -nrk 5 > $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/ExogenousGenomicAlignments.result.txt
	# tidy up
	rm $(OUTPUT_DIR)/$(SAMPLE_ID)/EXOGENOUS_genomes/tmp*




##
## Main sub-target
##
processSample: $(OUTPUT_DIR)/$(SAMPLE_ID)/$(PROCESS_SAMPLE_REQFILE)
	## Copy Output descriptions file
	cp $(SRNABENCH_LIBS)/sRNAbenchOutputDescription.txt $(OUTPUT_DIR)/$(SAMPLE_ID)/sRNAbenchOutputDescription.txt 
	##
	## Calculate QC result
	cat $(OUTPUT_DIR)/$(SAMPLE_ID).stats | grep "^genome" | awk '{print $$2}' > $(OUTPUT_DIR)/tmp.txt
	cat $(OUTPUT_DIR)/$(SAMPLE_ID).stats | grep "sense" | awk '{SUM+=$$2}END{print SUM}' >> $(OUTPUT_DIR)/tmp.txt
	cat $(OUTPUT_DIR)/tmp.txt | tr '\n' '\t' | awk '{result="FAIL"; ratio=$$2/$$1; if(ratio>$(MIN_GENOME_TRANSCRIPTOME_RATIO) && $$2>$(MIN_TRANSCRIPTOME_MAPPED))result="PASS"}END{print "QC_result: "result"\nGenomeReads: "$$1"\nTranscriptomeReads: "$$2"\nTranscriptomeGenomeRatio: "ratio}' > $(OUTPUT_DIR)/$(SAMPLE_ID).qcResult
	rm $(OUTPUT_DIR)/tmp.txt
	##
	## END PIPELINE
	@echo -e "$(ts) SMRNAPIPELINE: END smallRNA-seq Pipeline for sample $(SAMPLE_ID)\n======================\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).log
	@echo -e "$(ts) SMRNAPIPELINE: END\n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).err
	@echo -e "#END OF STATS from smallRNA-seq Pipeline for sample $(SAMPLE_ID) \n" >> $(OUTPUT_DIR)/$(SAMPLE_ID).stats


##
##
##
