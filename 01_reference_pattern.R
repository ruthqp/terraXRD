#Script 01: Build the reference patterns from RRUFF and AMCSD DIF files
##Input:  DIF files in reference/rruff/ (RRUFF) and reference/amcsd/ (AMCSD),
##one file per mineral
##Output: output/01_reference_patterns.csv (all peaks of all minerals, one table)
##
##To add a mineral: download its DIF file, save it in the right folder with the
##original name, and run this script again. No code changes needed.
##AMCSD is used only for minerals without a DIF file in RRUFF.

#Packages-----
library(tidyverse)

#Step 1: List the DIF files-----
#1. Set the working directory to the project folder
setwd("~/Documents/Steve Lab/Svalbard/XRD_Analysis/terraXRD_project")

#2. Find all DIF files in the two folders
## RRUFF names:  Quartz__R040031-1__Powder__DIF_File__<code>.txt
## AMCSD names:  Kaolinite__0020861.dif
rruff_files <- list.files("reference/rruff", pattern = "DIF_File", full.names = TRUE)
amcsd_files <- list.files("reference/amcsd", pattern = "\\.dif$", full.names = TRUE)
dif_files   <- c(rruff_files, amcsd_files)
dif_files
length(dif_files)   ##number of minerals

#Step 2: Write a function that reads one DIF file-----
## This function contains the same steps we did for quartz:
## read the lines, find the peak table, sum peaks with the same d-spacing,
## convert d-spacing to 2-theta for the Terra (Cu, 1.5406 A), keep 5-55 degrees.
## Writing it as a function lets us apply it to every file in the folder.

lambda_terra <- 1.5406   ##Cu K-alpha1,from the Terra .plv file

read_dif <- function(dif_file) {
  
  # 1. Mineral name, source and ID from the file name
  ## RRUFF: Quartz__R040031-1__Powder__DIF_File__<code>.txt -> Quartz, R040031
  ## AMCSD: Kaolinite_0020861.dif or Kaolinite__0020861.dif -> Kaolinite, 0020861
  ## The mineral name is the text before the first "_".
  file_name <- basename(dif_file)
  mineral   <- str_extract(file_name, "^[^_]+")
  source    <- if_else(str_detect(dif_file, "amcsd"), "AMCSD", "RRUFF")
  ref_id    <- if_else(source == "RRUFF",
                       str_extract(file_name, "R[0-9]+"),             ##R + digits
                       str_extract(file_name, "[0-9]+(?=\\.dif$)"))   ##digits before .dif
  
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
    summarise(intensity = sum(intensity)) %>%
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
reference_patterns %>% count(source, mineral, ref_id) %>% print(n = Inf)
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
ggsave("output/01_reference_patterns.png", reference_plot,
       width = 10, height = 2 + 2 * ceiling(length(dif_files) / 4), dpi = 300)
## The height grows with the number of minerals (4 panels per row)

#Step 5: Save the table-----
write_csv(reference_patterns, "output/01_reference_patterns.csv")

