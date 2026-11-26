#####Reference patterns of the candidate minerals ---------
#Let's build the reference patterns of the minerals we expect in our samples.
#We are going to save all the peaks of the minerals from the two datasets into just one table as "01_reference_patterns.csv".
#If you add a new DIF file (for a new mineral), you should run this script again.

source("~/Documents/Steve Lab/terraXRD_github/steps/00_settings.R")

#Packages-----
library(tidyverse)

#Elements from the DIF file we are going to use:

##D-spacing: It does not depend on the X-ray wavelength, so we use it to calculate the 2θ
#of each peak for the Terra with Bragg's law: nλ = 2d sinθ (n = 1), therefore 2θ=2arcsin (λ/2d) 
#Bragg and Bragg, 1913.
#For example: quartz, d=3.3432 Å, 26.6 for the terra instrument.
##Intensity: relative intensity of each peak (Cullity and Stock, 2001, ch. 4).
#The 2θ column of the DIF files is calculated for another wavelength (1.541838 Å), so we don't use it.

#Step 1: List the DIF files-----
## RRUFF names:  Quartz__R040031-1__Powder__DIF_File.txt
## AMCSD names:  Kaolinite__0020861.dif
rruff_files <- list.files(rruff_dir, pattern = "DIF_File", full.names = TRUE)
amcsd_files <- list.files(amcsd_dir, pattern = "\\.dif$", full.names = TRUE)
dif_files   <- c(rruff_files, amcsd_files)
dif_files
length(dif_files)   ## number of minerals

#Step 2: Function to read one DIF file-----
## This function contains the same steps we did for quartz:
## read the lines, find the peak table, sum peaks with the same d-spacing,
## convert d-spacing to 2-theta for the Terra (Cu, 1.5406 A), keep 5-55 degrees.
## Writing it as a function lets us apply it to every file in the folder.

lambda_terra <- 1.5406   ## Cu K-alpha1, from the Terra .plv file

read_dif <- function(dif_file) {
  
  # 1. Mineral name, source and ID from the file name
  ## RRUFF: Quartz__R040031-1__Powder__DIF_File__<code>.txt -> Quartz, R040031
  ## AMCSD: Kaolinite_0020861.dif or Kaolinite__0020861.dif -> Kaolinite, 0020861
  ## The mineral name is the text before the first "_".
  file_name <- basename(dif_file)
  mineral   <- str_extract(file_name, "^[^_]+")
  source    <- if_else(str_detect(dif_file, "amcsd"), "AMCSD", "RRUFF")
  ref_id    <- if_else(source == "RRUFF",
                       str_extract(file_name, "R[0-9]+"),             ## R + digits
                       str_extract(file_name, "[0-9]+(?=\\.dif$)"))   ## digits before .dif
  
  # 2. Read the lines and find the peak table
  ## The table starts after the line with "2-THETA".
  ## Some files end the table with a "=====" line and some do not, so we keep
  ## the lines after "2-THETA" while they start with numbers, and stop at the
  ## first line that does not (empty line, "=====" or text).
  dif_lines  <- readLines(dif_file)
  start_line <- grep("2-THETA", dif_lines) + 1
  after      <- dif_lines[start_line:length(dif_lines)]
  is_peak    <- str_detect(after, "^\\s*[0-9.]+\\s+[0-9.]+\\s+[0-9.]+")
  n_peaks    <- if_else(all(is_peak), length(after), which(!is_peak)[1] - 1L)
  peaks_raw  <- read.table(text = after[1:n_peaks])
  
  # 3. Keep intensity and d-spacing (columns 2 and 3)
  ## Column 1 (2-theta) is for lambda = 1.541838, not the Terra, so we drop it.
  ## Columns h, k, l (and Multiplicity in AMCSD files) are not needed.
  peaks_raw %>%
    select(intensity = V2, d_spacing = V3) %>%
    # 4. Sum peaks with the same d-spacing (they appear as one peak)
    group_by(d_spacing) %>%
    dplyr::summarise(intensity = sum(intensity)) %>%
    arrange(desc(d_spacing)) %>%
    # 5. Relative intensity (strongest peak = 100) and 2-theta for the Terra
    mutate(rel_intensity = 100 * intensity / max(intensity),
           two_theta = 2 * asin(lambda_terra / (2 * d_spacing)) * 180 / pi) %>%
    # 6. Keep the Terra range
    filter(two_theta >= 5, two_theta <= 55) %>%
    # 7. Citation columns
    mutate(mineral = mineral,
           source = source,
           ref_id = ref_id,
           downloaded = as.Date(file.info(dif_file)$mtime))
  ## downloaded = date the file was saved on your computer
}

#Step 3: Read all DIF files into one table-----
# 1. Apply the function to every file and stack the results
## map_dfr() runs read_dif() on each file and joins the tables by rows.
reference_patterns <- map_dfr(dif_files, read_dif)
head(reference_patterns)
dim(reference_patterns)

# 2. Check: number of peaks per mineral
reference_patterns %>% dplyr::count(source, mineral, ref_id) %>% print(n = Inf)
## Quartz (R040031) should have 9 peaks

#Step 4: Plot the reference patterns-----
# 1. One panel per mineral, vertical lines (sticks) at each peak
reference_plot <- ggplot(reference_patterns) +
  geom_segment(aes(x = two_theta, xend = two_theta, y = 0, yend = rel_intensity),
               color = "#005f99", linewidth = 0.8) +
  facet_wrap(~ mineral, ncol = 4) +
  coord_cartesian(xlim = c(5, 55)) +
  labs(title = "Reference patterns (RRUFF and AMCSD, Cu K-alpha1)",
       x = "2-theta (degrees)", y = "Relative intensity") +
  theme_classic()
reference_plot

#You can save this plot if you want 
ggsave(file.path(output_dir, "01_reference_patterns.png"), reference_plot,
       width = 10, height = 2 + 2 * ceiling(length(dif_files) / 4), dpi = 300)
#And you can save this information as a table (This will be necessary later on)
write_csv(reference_patterns, file.path(output_dir, "01_reference_patterns.csv"))

#References ----
#Bragg, W. H., and Bragg, W. L. (1913). The reflection of X-rays by crystals.
#Proc. R. Soc. Lond. A 88, 428-438. doi:10.1098/rspa.1913.0040
#Cullity, B. D., and Stock, S. R. (2001). Elements of X-Ray Diffraction, 3rd Edn.
#Upper Saddle River, NJ: Prentice Hall.

