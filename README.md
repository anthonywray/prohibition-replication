# Replication code and data for "Later-life Mortality and the Repeal of Federal Prohibition"
 
---
contributors:
  - David S. Jacks
  - Krishna Pendakur
  - Hitoshi Shigeoka
  - Anthony Wray
---

# README

## Overview

The code in this replication package constructs the analysis datasets used to reproduce the figures and tables in the following article:

Jacks, David S., Krishna Pendakur, Hitoshi Shigeoka, and Anthony Wray. "Later-life Mortality and the Repeal of Federal Prohibition." Forthcoming at the _Journal of Public Economics_.

Some public-use datasets from IPUMS USA cannot be included in the repository. These must first be downloaded using the IPUMS data extraction system before running our code. Instructions for accessing data from IPUMS USA are provided below. 

The code is executed using Stata version 17 and R version 4.4.1. To recreate our paper, navigate to the home directory `prohibition-replication` and open the Stata project `prohibition-replication.stpr`, then run the do file `0_run_all.do`. This will run all of the code to create the figures and tables in the manuscript, including the online appendix. The replicator should expect the code to run for about 26 minutes.

## Data Availability and Provenance Statements

### Statement about Rights

- I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the [LICENSE.txt](LICENSE.txt) file.

### License for Data

The data are licensed under a MIT License license. See LICENSE.txt for details.

### Summary of Availability

- All data **are** publicly available.

### Details on each Data Source

The data used to support the findings of this study have been deposited in a replication package hosted at OpenICPSR ([project openicpsr-208062](https://doi.org/10.3886/E208062V1)). Data are made available under a MIT license. Here we provide further details on the sources for all datasets used in the study:

The paper uses a crosswalk file with __USPS state abbreviations and FIPS codes__ available from [Bureau of Labor Statistics (2005)](https://www.bls.gov/respondents/mwr/electronic-data-interchange/appendix-d-usps-state-abbreviations-and-fips-codes.htm).

The __state-level personal income per capita__ measures for 1929 to 2018 originate from reports by the Bureau of Economic Analysis and represent "personal income measures that include transfers to capture purchasing power output-based measures of income or government spending" (Fishback 2015, p. 98). The data was retrieved from FRED at the Federal Reserve Bank of St. Louis [(Bureau of Economic Analysis 2023)](https://fred.stlouisfed.org/series/A229RX0A048NBEA).

The paper uses __IPUMS USA__ [full count U.S. Census microdata](https://usa.ipums.org/usa/full_count.shtml). IPUMS USA does not allow users to redistribute IPUMS-USA Full-Count data, but these data can be freely downloaded from the [IPUMS-USA extract system](https://usa.ipums.org/usa-action/variables/group). Users must first fill out the registration form, including a brief description of the project, and agree to the conditions of use. In lieu of providing a copy of the data files as part of this archive, we include codebook files for each of the four full count extracts used, which provide information on the variables and observations to be selected. 

The paper also uses the 5% sample of the 1990 US Census of Population provided by __IPUMS USA__ (Ruggles et al. 2023) to produce estimates of the state-by-year of birth cohort size in 1990. The data can be downloaded from [IPUMS USA](https://usa.ipums.org/usa-action/samples). Users will first need to [register for an account](https://uma.pop.umn.edu/usa/user/new) with IPUMS USA. We also include the codebook file (`usa_00071.cbk`) and the do file (`usa_00071.do`) provided by IPUMS along with the data. The data was downloaded on 15 November 2021. Interested  replicators can use the list of variables in the codebook file to generate an identical extract from the IPUMS system. In such cases with non-full count data, IPUMS USA does not allow for redistribution without permission, but their [terms of use](https://usa.ipums.org/usa/terms.shtml) makes an exception for users to "publish a subset of the data to meet journal requirements for accessing data related to a particular publication." 

The paper uses a crosswalk file for converting __NCHS state codes to FIPS state__ codes that was downloaded from the NBER website ([National Bureau of Economic Research 2016)](https://data.nber.org/data/nchs-fips-county-crosswalk.html)). Note that the source file has an error. The FIPS state code for Georgia is listed as 12 and it should be 13.

The __mortality outcomes__ are constructed from a public-use version of the NCHS Multiple Cause-of-Death Mortality Data from the National Vital Statistics System (National Center for Health Statistics, 1979-2004). The data are provided by the [National Bureau of Economic Research (NBER)](https://www.nber.org/research/data/mortality-data-vital-statistics-nchs-multiple-cause-death-data). 

To ensure the comparability of the categories of the causes of death across the Ninth and Tenth Revisions of the _International Classification of Diseases_ we followed the crosswalk provided by [Anderson et al. (2001)](https://www.cdc.gov/nchs/data/nvsr/nvsr49/nvsr49_02.pdf).

The __New Deal funding__ data were obtained via email correspondence from Price Fishback. The data file underlies the tables reported in the study "New Deal Funding: Estimates of Federal Grants and Loans across States by Year, 1930–1940" [Fishback (2015)](https://doi.org/10.1108/S0363-326820150000031002).

The paper uses US Census GIS shapefile data from __IPUMS NHGIS__ (Manson et al. 2022) to create maps of state-level prohibition status. The shapefiles were last downloaded on 14 May 2023 from [IPUMS NHGIS](https://www.nhgis.org/). IPUMS NHGIS does not allow for redistribution without permission, but their [terms of use](https://www.nhgis.org/ipums-nhgis-terms-use) makes an exception for users to "publish a subset of the data to meet journal requirements for accessing data related to a particular publication." A copy of the data files are provided as part of this archive.

The county-by-year binary indicator for __prohibition status__ between 1933 and 1942 is obtained from the replication materials for [Jacks, Pendakur and Shigeoka (2021)](https://doi.org/10.1093/ej/ueab011) which includes further information on the construction of the prohibition data. Among variables used in the analysis, the data set also includes the number of births in each state-by-year cohort. 

## Dataset list

The following table provides a list of all datasets included in this replication package (stored within the `analysis/raw` directory) and their provenance.

| Data file and subdirectory                | Source                       | Notes                                       |Provided |
|-------------------------------------------|------------------------------|---------------------------------------------|---------|
| `bls/stateabb.dta`                        | Bureau of Labor Statistics (2005) | Crosswalk from USPS state abbreviations to FIPS codes | Yes |
| `great_depression/State-level personal income per capita, 1929-2018.xlsx` | Fishback (2015, p. 98) and Bureau of Economic Analysis (2023) | State-level income per capita | Yes | 
| `ipums/ipums_1940_100_pct/usa_00090.dat`  | Ruggles et al. (2023) | 1940 US Full-Count Census | No |
| `ipums/ipums_1950_100_pct/usa_00089.dat`  | Ruggles et al. (2023) | 1940 US Full-Count Census | No |
| `ipums/usa_00083.dat`                     | Ruggles et al. (2023) | 5% sample of 1990 U.S. Census | Yes |
| `nber_mortality_mcod/nchs2fips_county1990.dta` | National Bureau of Economic Research (2016) | Crosswalk from NCHS state codes to FIPS state | Yes | 
| `nber_mortality_mcod/dta/mort1979dta.zip` | National Center for Health Statistics (1979) | Multiple Cause-of-Death Mortality Data for 1979 | Yes | 
| `nber_mortality_mcod/dta/mort1980dta.zip` | National Center for Health Statistics (1980) | Multiple Cause-of-Death Mortality Data for 1980 | Yes |
| `nber_mortality_mcod/dta/mort1981dta.zip` | National Center for Health Statistics (1981) | Multiple Cause-of-Death Mortality Data for 1981 | Yes |
| `nber_mortality_mcod/dta/mort1982dta.zip` | National Center for Health Statistics (1982) | Multiple Cause-of-Death Mortality Data for 1982 | Yes |
| `nber_mortality_mcod/dta/mort1983dta.zip` | National Center for Health Statistics (1983) | Multiple Cause-of-Death Mortality Data for 1983 | Yes |
| `nber_mortality_mcod/dta/mort1984dta.zip` | National Center for Health Statistics (1984) | Multiple Cause-of-Death Mortality Data for 1984 | Yes |
| `nber_mortality_mcod/dta/mort1985dta.zip` | National Center for Health Statistics (1985) | Multiple Cause-of-Death Mortality Data for 1985 | Yes |
| `nber_mortality_mcod/dta/mort1986dta.zip` | National Center for Health Statistics (1986) | Multiple Cause-of-Death Mortality Data for 1986 | Yes |
| `nber_mortality_mcod/dta/mort1987dta.zip` | National Center for Health Statistics (1987) | Multiple Cause-of-Death Mortality Data for 1987 | Yes |
| `nber_mortality_mcod/dta/mort1988dta.zip` | National Center for Health Statistics (1988) | Multiple Cause-of-Death Mortality Data for 1988 | Yes |
| `nber_mortality_mcod/dta/mort1989dta.zip` | National Center for Health Statistics (1989) | Multiple Cause-of-Death Mortality Data for 1989 | Yes |
| `nber_mortality_mcod/dta/mort1990dta.zip` | National Center for Health Statistics (1990) | Multiple Cause-of-Death Mortality Data for 1990 | Yes |
| `nber_mortality_mcod/dta/mort1991dta.zip` | National Center for Health Statistics (1991) | Multiple Cause-of-Death Mortality Data for 1991 | Yes |
| `nber_mortality_mcod/dta/mort1992dta.zip` | National Center for Health Statistics (1992) | Multiple Cause-of-Death Mortality Data for 1992 | Yes |
| `nber_mortality_mcod/dta/mort1993dta.zip` | National Center for Health Statistics (1993) | Multiple Cause-of-Death Mortality Data for 1993 | Yes |
| `nber_mortality_mcod/dta/mort1994dta.zip` | National Center for Health Statistics (1994) | Multiple Cause-of-Death Mortality Data for 1994 | Yes |
| `nber_mortality_mcod/dta/mort1995dta.zip` | National Center for Health Statistics (1995) | Multiple Cause-of-Death Mortality Data for 1995 | Yes |
| `nber_mortality_mcod/dta/mort1996dta.zip` | National Center for Health Statistics (1996) | Multiple Cause-of-Death Mortality Data for 1996 | Yes |
| `nber_mortality_mcod/dta/mort1997dta.zip` | National Center for Health Statistics (1997) | Multiple Cause-of-Death Mortality Data for 1997 | Yes |
| `nber_mortality_mcod/dta/mort1998dta.zip` | National Center for Health Statistics (1998) | Multiple Cause-of-Death Mortality Data for 1998 | Yes |
| `nber_mortality_mcod/dta/mort1999dta.zip` | National Center for Health Statistics (1999) | Multiple Cause-of-Death Mortality Data for 1999 | Yes |
| `nber_mortality_mcod/dta/mort2000dta.zip` | National Center for Health Statistics (2000) | Multiple Cause-of-Death Mortality Data for 2000 | Yes |
| `nber_mortality_mcod/dta/mort2001dta.zip` | National Center for Health Statistics (2001) | Multiple Cause-of-Death Mortality Data for 2001 | Yes |
| `nber_mortality_mcod/dta/mort2002dta.zip` | National Center for Health Statistics (2002) | Multiple Cause-of-Death Mortality Data for 2002 | Yes |
| `nber_mortality_mcod/dta/mort2003dta.zip` | National Center for Health Statistics (2003) | Multiple Cause-of-Death Mortality Data for 2003 | Yes |
| `nber_mortality_mcod/dta/mort2004dta.zip` | National Center for Health Statistics (2004) | Multiple Cause-of-Death Mortality Data for 2004 | Yes |
| `new_deal/reh3041.dta`                    | Fishback (2015) | New Deal spending | Yes |
| `nhgis/nhgis0032_shape/US_state_1930.*`   | Manson et al. (2022) | NHGIS US state boundaries (1930) | Yes |
| `nhgis/nhgis0033_shape/US_county_1930.*`  | Manson et al. (2022) | NHGIS US county boundaries (1930) | Yes |
| `prohibition/prohibition_status_by_state_1933-1942.dta` | Jacks et al. (2021) | Prohibition status | Yes | 
| `prohibition/full19301942.dta`            | Jacks et al. (2021) | Prohibition status | Yes | 


## Computational requirements



### Software Requirements


- The replication package contains all programs used for computation in the `analysis/scripts/libraries/stata` and `analysis/scripts/libraries/R` directories.  

All software used for stata is contained within the `analysis/scripts/libraries/stata` directory. If you would like to use updated versions of this code (which may be different than the versions we used) you may install stata packages using the `analysis/scripts/code/_install_stata_packages.do` file. Note that you may need to delete and then reinstall all the packages in `analysis/scripts/libraries/stata/g` related to gtools since gtools will install machine specific libraries. 

Packages and version control related to R should be in `analysis/scripts/libraries/R` and are controlled using `renv` package. Please see the file `analysis/scripts/code/_install_R_packages.R`.

- Stata (Version 17)
- R 4.4.1

Portions of the code require data to be unzipped using a program such as 7-Zip. 

### Controlled Randomness

- Whenever a random seed is used we use `12345`. These are set on the following lines, in the following scripts. 

  - Line 53 of `analysis/scripts/code/5_online_appendix.do`

### Memory, Runtime, Storage Requirements


#### Summary

Approximate time needed to reproduce the analyses on a standard (2024) desktop machine:

- Less than 1 hour

Approximate storage space needed:

- 10 GB - 15 GB

#### Details

The code was last run on a **Lenovo X1 Carbon Gen 11 with a 13th Gen Intel(R) Core(TM) i7-1370P, 1900 Mhz, 14 core processor, running Microsoft Windows 11 Pro with 64 GB of RAM and 2TB of free space**. Computation took **25 minutes 44 seconds** to run.

Each section of the code took the following time to run

- Build data: 21 minutes
- Main figures and tables: 1.2 minutes
- Online appendix: 4 minutes

## Description of programs/code

- The program `0_run_all.do` will run all programs in the sequence listed below. If running in any order other than the one outlined above, your results may differ.
  - Custom ado files have been stored in the `analysis/scripts/programs` directory and ado packages have been included in the `analysis/scripts/libraries` directory. The `0_run_all.do` file sets the `.ado` directories appropriately. 
- The program `analysis/scripts/code/1_import_data.do` will extract and reformat all datasets referenced above.  
  - The program `analysis/scripts/programs/_ipums_labels.do` is called by `analysis/scripts/code/1_import_data.do` to add value labels to IPUMS data. 
- The program `analysis/scripts/code/2_clean_data.do` cleans all datasets provided in the public repository.
- The program `analysis/scripts/code/3_combine_data.do` compiles all the datasets generated from public datasets to create the analysis datasets. 
  - The program `analysis/scripts/programs/estreat.ado` is called by `analysis/scripts/code/3_combine_data.do` to create the difference-in-differences treatment variables.
- The program `analysis/scripts/code/4_tables_figures.do` generates all tables and figures in the main body of the article.
  - The program `analysis/scripts/programs/create_maps.R` is called by `analysis/scripts/code/4_tables_figures.do` to generate the maps in Figure 1c and Appendix Figure C2.
  - The names of output files begin with an appropriate prefix (e.g. `table_3_*.tex`, `figure_2b_*.pdf`) and should be easy to correlate with the manuscript. In figures with multiple sub-elements, the prefix of the file name includes, in order, the figure number and the panel (as displayed in the manuscript). 
- The program `analysis/scripts/code/5_online_appendix.do` generates all tables and figures in the online appendix. 
  - The program `analysis/scripts/programs/create_county_map.R` is called by `analysis/scripts/code/5_online_appendix.do` to generate the map in Appendix Figure C1.

### License for Code

The code is licensed under a MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

To perform a clean run

1. Be sure to have downloaded the publicly available IPUMS data that we are not allowed to redistribute

    - The extract from the 1940 full count census must be downloaded to `analysis/raw/ipums/ipums_1940_100_pct/`
    - The extract from the 1950 full count census must be downloaded to `analysis/raw/ipums/ipums_1950_100_pct/`

2. Delete the following two directories:
  
    - `/processed`
    - `/output`

3. Open the stata project `prohibition-replication.stpr` or make sure the working directory of Stata is the same as the directory in which `prohibition-replication.stpr` is located 

4. Modify the following lines of the file `0_run_all.do`:

    - Users must specify the path to the installation of R (`Rscript.exe`) on line 65 
    - Users must specify the path to the relevant application for unzipping files on line 66

5. Modify the following lines of the file `1_import_data.do`:

  - Users must modify lines 17-18 of `analysis/scripts/code/1_import_data.do` with the filenames of the 1940 and 1950 full-count census extracts that are not provided in the replication package.

6. Run the file `0_run_all.do`



## List of tables and programs

The provided code reproduces:

- All tables and figures in the paper


| Figure/Table #    | Program                                       | Line Numbers | Output File                                             | Note                            |
|-------------------|-----------------------------------------------|--------------|---------------------------------------------------------|---------------------------------|
| Figure 1a         | analysis/scripts/code/4_tables_figures.do     | 62-79        | figure_1a_ethanol_consumption.png                       ||
| Figure 1b         | analysis/scripts/code/4_tables_figures.do     | 108-122      | figure_1b_shr_pop_treated.png                           ||
| Figure 1c         | analysis/scripts/programs/create_maps.R       | 85           | figure_1c_wet_map.png                                   ||
| Figure 1d         | analysis/scripts/code/4_tables_figures.do     | 152-174      | figure_1d_resid_death_by_birthyear.png                  ||
| Figure 2a         | analysis/scripts/code/4_tables_figures.do     | 275-324      | figure_2a_event_study_deaths.png                        ||
| Figure 2b         | analysis/scripts/code/4_tables_figures.do     | 275-324      | figure_2b_event_study_heart.png                         ||
| Figure 2c         | analysis/scripts/code/4_tables_figures.do     | 275-324      | figure_2c_event_study_stroke.png                        ||
| Figure 2d         | analysis/scripts/code/4_tables_figures.do     | 275-324      | figure_2d_event_study_cancer.png                        ||
| Table 1           | analysis/scripts/code/4_tables_figures.do     | 586-635      | table_1_aggregate_event_study_regressions.tex           ||
| Table 2           | analysis/scripts/code/4_tables_figures.do     | 700-732      | table_2_cause_of_death.tex                              ||
| Table 3           | analysis/scripts/code/4_tables_figures.do     | 929-968      | table_3_heterogeneity.tex                               ||
| Figure A1         | analysis/scripts/code/5_online_appendix.do    | 79-84        | figure_a1_n_treated_units.png                           ||
| Figure A2         | analysis/scripts/code/4_tables_figures.do     | 275-324      | figure_a2_event_study_mv_acc.png                        ||
| Figure A3a        | analysis/scripts/code/5_online_appendix.do    | 312-351      | figure_a3a_es_robust_controls_deaths.png                ||
| Figure A3b        | analysis/scripts/code/5_online_appendix.do    | 312-351      | figure_a3b_es_robust_controls_heart.png                 ||
| Figure A3c        | analysis/scripts/code/5_online_appendix.do    | 312-351      | figure_a3c_es_robust_controls_stroke.png                ||
| Figure A3d        | analysis/scripts/code/5_online_appendix.do    | 312-351      | figure_a3d_es_robust_controls_cancer.png                ||
| Table A1          | analysis/scripts/code/5_online_appendix.do    | 358-370      | table_a1_icd_crosswalk.tex                              ||
| Table A2          | analysis/scripts/code/5_online_appendix.do    | 563-605      | table_a2_bounding_infant_deaths_by_year_1990_start.tex  ||
| Table A3          | analysis/scripts/code/5_online_appendix.do    | 1267-1274    | table_a3_life_cycle_mortality.tex                       ||
| Figure B1a        | analysis/scripts/code/5_online_appendix.do    | 1379-1417    | figure_b1a_es_extended_panel_deaths.png                 ||
| Figure B1b        | analysis/scripts/code/5_online_appendix.do    | 1379-1417    | figure_b1b_es_extended_panel_heart.png                  ||
| Figure B1c        | analysis/scripts/code/5_online_appendix.do    | 1379-1417    | figure_b1c_es_extended_panel_stroke.png                 ||
| Figure B1d        | analysis/scripts/code/5_online_appendix.do    | 1379-1417    | figure_b1d_es_extended_panel_cancer.png                 ||
| Table B1          | analysis/scripts/code/5_online_appendix.do    | 1499-1506    | table_b1_extended_panel.tex                             ||
| Figure C1         | analysis/scripts/programs/create_county_map.R | 78           | figure_c1_county_wet_map.png                            ||
| Figure C2         | analysis/scripts/programs/create_maps.R       | 100          | figure_c2_continuous_map.png                            ||
| Table C1          | analysis/scripts/code/5_online_appendix.do    | 1570-1577    | table_c1_continuous_treatment.tex                       ||
| Figure D1a        | analysis/scripts/code/5_online_appendix.do    | 1691-1731    | figure_d1a_es_cumulative_deaths.png                     ||
| Figure D1b        | analysis/scripts/code/5_online_appendix.do    | 1691-1731    | figure_d1b_es_cumulative_heart.png                      ||
| Figure D1c        | analysis/scripts/code/5_online_appendix.do    | 1691-1731    | figure_d1c_es_cumulative_stroke.png                     ||
| Figure D1d        | analysis/scripts/code/5_online_appendix.do    | 1691-1731    | figure_d1d_es_cumulative_cancer.png                     ||
| Table D1          | analysis/scripts/code/5_online_appendix.do    | 1814-1821    | table_d1_cumulative.tex                                 ||
| Figure E1a        | analysis/scripts/code/5_online_appendix.do    | 1940-1959    | figure_e1a_event_study_women_only.png                   ||
| Figure E1b        | analysis/scripts/code/5_online_appendix.do    | 1940-1959    | figure_e1b_event_study_men_only.png                     ||
| Figure E1c        | analysis/scripts/code/5_online_appendix.do    | 1940-1959    | figure_e1c_event_study_non_white_only.png               ||
| Figure E1d        | analysis/scripts/code/5_online_appendix.do    | 1940-1959    | figure_e1d_event_study_white_only.png                   ||

## Data citations 

Anderson RN, Miniño AM, Hoyert DL, Rosenberg HM. Comparability of cause of death between ICD–9 and ICD–10: Preliminary estimates. National vital statistics reports. Vol 49 No. 2. Hyattsville, Maryland: National Center for Health Statistics. 2001.

Bureau of Economic Analysis. 2023. "Real Disposable Personal Income: Per Capita A229RX0A048NBEA." Last Accessed January 2, 2023. Retrieved from FRED, Federal Reserve Bank of St. Louis. https://fred.stlouisfed.org/series/A229RX0A048NBEA.

Bureau of Labor Statistics. 2005. "Appendix D - USPS State Abbreviations and FIPS Codes." Accessed August 29, 2022. https://www.bls.gov/respondents/mwr/electronic-data-interchange/appendix-d-usps-state-abbreviations-and-fips-codes.htm. 

Fishback, Price V. 2015. "New Deal Funding: Estimates of Federal Grants and Loans across States by Year, 1930–1940," Research in Economic History, Vol. 31, pp. 41-109. https://doi.org/10.1108/S0363-326820150000031002. 

Jacks, David S., Krishna Pendakur, Hitoshi Shigeoka. 2021. "Infant Mortality and the Repeal of Federal Prohibition," The Economic Journal, Vol. 131 No. 639, pp. 2955–2983. https://doi.org/10.1093/ej/ueab011.

Manson, Steven, Jonathan Schroeder, David Van Riper, Tracy Kugler, and Steven Ruggles. 2022. IPUMS National Historical Geographic Information System: Version 17.0 [dataset]. Minneapolis, MN: IPUMS. http://doi.org/10.18128/D050.V17.0.

National Bureau of Economic Research. 2016. "NCHS to FIPS County Crosswalk." Last Accessed August 29, 2022. https://data.nber.org/data/nchs-fips-county-crosswalk.html.

National Center for Health Statistics. 1979-2004. Data File Documentations, Multiple Cause-of-Death, 1979-2004 (machine readable data file and documentation, CD-ROM Series Series Number, No. 20), National Center for Health Statistics, Hyattsville, Maryland.

Ruggles, Steven, Sarah Flood, Matthew Sobek, Daniel Backman, Annie Chen, Grace Cooper, Stephanie Richards, Renae Rogers, and Megan Schouweiler. 2023. IPUMS USA: Version 14.0 [dataset]. Minneapolis, MN: IPUMS. https://doi.org/10.18128/D010.V14.0.


## Package Citations

### Stata

Baum, C.F., Schaffer, M.E. 2013.  avar: Asymptotic covariance estimation for iid and non-iid data robust to heteroskedasticity, autocorrelation, 1- and 2-way clustering, common cross-panel autocorrelated disturbances, etc. http://ideas.repec.org/c/boc/bocode/XXX.html, revised 28 July 2015.

Daniel Bischof, 2016. "BLINDSCHEMES: Stata module to provide graph schemes sensitive to color vision deficiency," Statistical Software Components S458251, Boston College Department of Economics, revised 07 Aug 2020.

Kirill Borusyak, 2021. "EVENT_PLOT: Stata module to plot the staggered-adoption diff-in-diff ("event study") estimates," Statistical Software Components S458958, Boston College Department of Economics, revised 26 May 2021. 

Tony Brady, 1998. "UNIQUE: Stata module to report number of unique values in variable(s)," Statistical Software Components S354201, Boston College Department of Economics, revised 18 Jun 2020.

Mauricio Caceres Bravo, 2018. "GTOOLS: Stata module to provide a fast implementation of common group commands," Statistical Software Components S458514, Boston College Department of Economics, revised 05 Dec 2022.

Sergio Correia, 2016. "FTOOLS: Stata module to provide alternatives to common Stata commands optimized for large datasets," Statistical Software Components S458213, Boston College Department of Economics, revised 21 Aug 2023.

Sergio Correia, 2014. "REGHDFE: Stata module to perform linear or instrumental-variable regression absorbing any number of high-dimensional fixed effects," Statistical Software Components S457874, Boston College Department of Economics, revised 21 Aug 2023.

Kevin Crow, 2006. "SHP2DTA: Stata module to converts shape boundary files to Stata datasets," Statistical Software Components S456718, Boston College Department of Economics, revised 17 Jul 2015.

Clément de Chaisemartin & Xavier D'Haultfoeuille & Yannick Guyonvarch, 2019. "DID_MULTIPLEGT: Stata module to estimate sharp Difference-in-Difference designs with multiple groups and periods," Statistical Software Components S458643, Boston College Department of Economics, revised 17 Dec 2023.

Ben Jann, 2004 "ESTOUT: Stata module to make regression tables," Statistical Software Components S439301, Boston College Department of Economics, revised 12 Feb 2023.

David Kantor, 2004. "CARRYFORWARD: Stata module to carry forward previous observations," Statistical Software Components S444902, Boston College Department of Economics, revised 15 Jan 2016.

David Molitor & Julian Reif, 2019. "RSCRIPT: Stata module to call an R script from Stata," Statistical Software Components S458644, Boston College Department of Economics, revised 03 Jun 2023.

Fernando Rios-Avila & Pedro H.C. Sant'Anna & Brantly Callaway, 2021. "CSDID: Stata module for the estimation of Difference-in-Difference models with multiple time periods," Statistical Software Components S458976, Boston College Department of Economics, revised 25 Feb 2023.

Fernando Rios-Avila & Pedro H.C. Sant'Anna & Asjad Naqvi, 2021. "DRDID: Stata module for the estimation of Doubly Robust Difference-in-Difference models," Statistical Software Components S458977, Boston College Department of Economics, revised 18 Oct 2022.

Liyang Sun, 2021. "EVENTSTUDYINTERACT: Stata module to implement the interaction weighted estimator for an event study," Statistical Software Components S458978, Boston College Department of Economics, revised 11 Sep 2022.

Liyang Sun, 2020. "EVENTSTUDYWEIGHTS: Stata module to estimate the implied weights on the cohort-specific average treatment effects on the treated (CATTs) (event study specifications)," Statistical Software Components S458833, Boston College Department of Economics, revised 04 Aug 2021.

Ben Zipperer, 2018. "lincomestadd." _GitHub_. https://github.com/benzipperer/lincomestadd/. Accessed August 30, 2023. 


---

## Acknowledgements

Some content on this page was copied from [Hindawi](https://www.hindawi.com/research.data/#statement.templates). Other content was adapted  from [Fort (2016)](https://doi.org/10.1093/restud/rdw057), Supplementary data, with the author's permission.
