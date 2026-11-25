knitr::opts_chunk$set(comment = NA)

Settings
================
Ruth E. Quispe-Pilco
2026-11-25

``` r
#####Settings for terraXRD processing ---------
#Let's define first the folders, the instrument settings, 
#and the list of samples used by all the scripts. 
#They are written here only once, so all scripts use the same values.
#Each script will load this script at the top with source ("steps/00_settings.R")

#Edit this for the first time when you start a new project with new samples.

setwd("~/Documents/Steve Lab/terraXRD_github") #This is the wd for the project. Inside there should be a samples and reference folder.

#Structure (folders) -----

sample_dir <- "samples" ##This is the folder we are using for our samples (Olympus Terra output)
#There will be one folder per sample, as exported by the Terra.
metadata_path <- "metadata/sample_metadata.csv" ##Change this to the name of your metadata.
#The columns of this metadata should be like this: 
#samples | site | factor_1 | factor_2 | ...| factor_n
#The 1st column should always be the sample, followed by "site o location" and many others factors.

#Group comparisons (optional)----
#If you want to compare samples per group (For example, sediment/soil type, location, treatments, etc).
##"sample_type" is the column we are using for our example.
group_column <- "sample_type" #If you don't want to compare, write NULL.
#If you want to organize your plots and diffractograms in an specific order (distance from the glacier, microbial richness level, nitrogen content, etc)
#"distance_m" is the column we are using for our example. It is the distance from the glacier.
order_column <- NULL #It is a numeric column (like distance). #Write NULL if you just want to order by sample name.

#Reference minerals (editable)----
#Here you will find **DIF** files (Diffraction peaks of a pure mineral).
#They are in .txt format, and have a header and a list of peaks. 
#In the peak list, there are columns for:
##2-theta (angle of the peak),
##Intensity: This is a relative intensity, calculated from the crystal structure of the mineral.
##D-spacing: Distance between the planes of atoms, in Å.
##H K L : Miller indexes (They identify the family of paralel planes inside the mineral)
##There is an additional column for files coming from AMCSD.
##Multiplicity : Number of equivalent planes that diffract at the same angle.
#The workflow compares your sample peaks with these reference minerals.
#For your own project, you should revise, check and modify these reference minerals file
#Minerals from RRUFF database
rruff_dir <- "reference/rruff" #For more info about rruff: https://www.rruff.net/
amcsd_files <- "reference/amcsd" #For more info about amcsd: https://www.rruff.net/amcsd/

#Output ----
output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

#Instrument ----
##Olympus Terra: Cu K-alpha1 radiation (value from terra file, .plv file)
lambda_terra <- 1.5406 ##Wavelength (Å)
range_2theta <- c(5,55) #Range (degrees 2θ) used by the instrument

#Sample files ----
#Here you will find all your XRD files per sample. Terra instrument saved the files as samplename-ka.txt.
#The files should be inside samplename/processed.
sample_files <- list.files(sample_dir, pattern = "-ka\\.txt$",
                           recursive = TRUE, full.names = TRUE)
sample_files
```

    ##  [1] "samples/FINE_ABS1_2_T1/processed/FINE_ABS1_2_T1-ka.txt"            
    ##  [2] "samples/FINE_ABS1_25_3_T1/processed/FINE_ABS1_25_3_T1-ka.txt"      
    ##  [3] "samples/FINE_ABS2_25_3_T1/processed/FINE_ABS2_25_3_T1-ka.txt"      
    ##  [4] "samples/FINE_ABS2_25_4_T1/processed/FINE_ABS2_25_4_T1-ka.txt"      
    ##  [5] "samples/FINE_ABS2_25_4_T2/processed/FINE_ABS2_25_4_T2-ka.txt"      
    ##  [6] "samples/FINE_ABS2_25_5_T1/processed/FINE_ABS2_25_5_T1-ka.txt"      
    ##  [7] "samples/FINE_ABS2_25_5_T2/processed/FINE_ABS2_25_5_T2-ka.txt"      
    ##  [8] "samples/FINE_BLK1_1_T1/processed/FINE_BLK1_1_T1-ka.txt"            
    ##  [9] "samples/FINE_BLK1_2_T1/processed/FINE_BLK1_2_T1-ka.txt"            
    ## [10] "samples/FINE_BLK1_3_T1/processed/FINE_BLK1_3_T1-ka.txt"            
    ## [11] "samples/FINE_BLK1_4_T1/processed/FINE_BLK1_4_T1-ka.txt"            
    ## [12] "samples/FINE_BLK1_5_T1/processed/FINE_BLK1_5_T1-ka.txt"            
    ## [13] "samples/FINE_BLK1_6_T1/processed/FINE_BLK1_6_T1-ka.txt"            
    ## [14] "samples/FINE_BLK2_6_T1/processed/FINE_BLK2_6_T1-ka.txt"            
    ## [15] "samples/FINE_clast_VBS1_25_1_T2/processed/FINE_VBS1_25_1_T2-ka.txt"
    ## [16] "samples/FINE_VBS1_25_1_T1/processed/FINE_VBS1_25_1_T1-ka.txt"      
    ## [17] "samples/FINE_VBS1_25_2_T1/processed/FINE_VBS1_25_2_t1-ka.txt"      
    ## [18] "samples/FINE_VBS1_25_3_T1/processed/FINE_VBS1_25_3_T1-ka.txt"      
    ## [19] "samples/FINE_VBS1_25_4_T1/processed/FINE_VBS1_25_4_T1-ka.txt"      
    ## [20] "samples/FINE_VBS2_25_1_T1/processed/FINE_VBS2_25_1_T1-ka.txt"      
    ## [21] "samples/FINE_VBS2_25_2_T1/processed/FINE_VBS2_25_2_T1-ka.txt"      
    ## [22] "samples/FINE_VBS2_25_2_T2/processed/FINE_VBS2_25_2_T2-ka.txt"      
    ## [23] "samples/FINE_VBS2_25_3_T1/processed/FINE_VBS2_25_3_T1-ka.txt"      
    ## [24] "samples/FINE_VBS2_25_4_T1/processed/FINE_VBS2_25_4_T1-ka.txt"      
    ## [25] "samples/FINE_VBS2_25_4_T2/processed/FINE_VBS2_25_4_T2-ka.txt"

``` r
#Sample names (Taking the sample files)
names(sample_files) <- sub("-ka\\.txt$","",
                           basename(sample_files))

#Check ----
#Message if something is missing
if (!dir.exists(sample_dir)){
  stop("Folder '", sample_dir, " ' not found. Check the setwd() line at the top of the script.")
}
if(length(sample_files) == 0) {
  warning("No '-ka.txt' files found in '",
          sample_dir, "'.",
          "Copy the Terra folders of your samples there.")
}
if (!file.exists(metadata_path)) {
  warning("Metadata file '", metadata_path, "' not found. ",
          "It is needed from Script 08 on (group comparison).")
}
message("terraXRD settings loaded: ", length(sample_files), " samples found in '",
        sample_dir, "'. Results will be saved in '", output_dir, "'.")
```

    ## terraXRD settings loaded: 25 samples found in 'samples'. Results will be saved in 'output'.

