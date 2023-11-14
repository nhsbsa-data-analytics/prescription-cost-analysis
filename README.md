# Prescription Cost Analysis

This code is published as part of the NHSBSA Official Statistics team's commitment to open code and transparency in how we produce our publications. The Prescription Cost Analysis (PCA) reproducible analytical pipeline (RAP) is owned and maintained by the Official Statistics team.

# Introduction

This RAP aims to bring together all code needed to run a pipeline in R to produce the PCA publication. It includes accompanying documentation in line with RAP best practice. 

The RAP includes a `functions` folder containing several files with functions specific to this publication. The RAP will produce an HTML report and accompanying HTML background and methodology document. This RAP makes use of many R packages, including several produced internally at the NHSBSA. Therefore, some of these packages cannot be accessed by external users. 

This RAP cannot be run in it's entirety by external users. However it should provide information on how the Official Statistics team extract the data from the NHSBSA data warehouse, analyse the data, and produce the outputs released on the NHSBSA website as part of this publication.

This RAP is a work in progress and may be replaced as part of updates and improvements for each new release of the PCA publication. The functions in the `functions` folder and PCA do not contain unit testing, although we will investigate adding this in future.

## Getting started

You can clone the repository containing the RAP through [GitHub](https://github.com/) using the following steps.

In RStudio, click on "New project", then click "Version Control" and select the "Git" option.

Click "Clone Git Repository" then enter the URL of the prescription-cost-analysis GitHub repository (https://github.com/nhsbsa-data-analytics/prescription-cost-analysis). You can click "Browse" to control where you want the cloned repository to be saved in your computer.

You will also need to create a [PAT key](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

You can view the [source code for the PCA RAP](https://github.com/nhsbsa-data-analytics/prescription-cost-analysis) on GitHub.

## Config

This RAP includes a `config.yml` file. Before running this pipeline you should ensure all variables in this file are set as required.

## Running this RAP

Users outside of the Official Statistics team may not have the required access permissions to run all parts of this RAP. The following information is included to document how this pipeline is run by members of the Official Statistics team during production.

Once the repository has been cloned, open the `pipeline.R` file and run the script from start to finish. If you do not already have them set up you will be prompted to add you `DB_DWCP_USERNAME` and `DB_DWCP_PASSWORD` to you `.Renviron` file. You will also be prompted as to whether or not you wish to generate the Excel outputs which accompany the publication. All other code in this script should require no other manual intervention.

The code should handle installing and loading any required packages and external data. It should then get data extracts from the PCA fact table, perform data manipulations, then save this data into spreadsheet outputs. The pipeline will then render the statistical summary narrative and background document as HTML files for use in web publishing.

## Functions guide

Functions used specifically for this RAP that aren't included in a package can be found in the [functions folder](https://github.com/nhsbsa-data-analytics/prescription-cost-analysis/tree/main/functions). The RAP also makes use of functions from a range of packages. A list of packages used is included at the beginning of the `pipeline.R` file, and installed and loaded within the pipeline code. Some functions contained in the functions folder may be placed into the internal NHSBSA packages in future.

Functions in this file include those for formatting in the narrative and downloading chart data directly and one amendment to our standard chart function `infoBox_border()`, `infoBox_no_border()`,  and `get_download_button()`.

# Contributing

Contributions are not currently being accepted for this RAP. If this changes, a contributing guide will be made available.

# License

The `prescription-cost-analysis` RAP, including associated documentation, is released under the MIT license. Details can be found in the `LICENSE` file.
