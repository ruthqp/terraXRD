# terraXRD
R scripts for processing XRD patterns from portable Olympus Terra XRD/XRF instrument and identify minerals phases qualitatively from natural samples, using reference minerals from the RRUFF and AMCSD databases. 

## See the workflow with a sample set as an example: 

Completed_workflow.md --> Here you will see the complete workflow with the code, results and plots, step by step.

This example uses samples from both, debris deposits and intermediary sediments from Midtre Lovénbreen glacier forefield.

## What do you need?

- **XRD patterns (from your samples)**
- **A metadata file**
- **R with "tidyverse" package**

We provide two reference minerals folders inside of "reference" folder, which includes minerals selected for **High-Arctic glacier sediments and soils (Svalbard)**. For other sites, revise the list in "reference/". 

RRUFF database: https://www.rruff.net/ , 
AMCSD database: https://www.rruff.net/amcsd/

## Associated publication

This workflow was developed for and used in:

Quispe-Pilco, R. E., et al. (submitted, 2026). Supraglacial geomorphology influences the rate and pattern of succession along a High-Arctic glacial foreland. Frontiers in Microbiology.

## Contact

Ruth E. Quispe-Pilco, Department of Ecology and Evolutionary Biology, University of Colorado Boulder (ruth.quispe@colorado.edu)
