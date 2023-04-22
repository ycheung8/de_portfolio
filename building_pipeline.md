Data Science Portfolio by Yi Cheung
https://ycheung8.github.io/

# Building a Machine Learning Pipeline

## Introduction

-	A machine learning pipeline orchestrates the flow of data into, and output from a machine learning model(s). 
-	Each component of a pipeline is called a step. 
-	We’ll focus on two types of methods: transform() and fit().

## Outline of Machine Learning Steps

1_ Preprocess
2_ Fill in Missing Values
3_ Convert categorical values into numerical values
4_ Scale or standardize the data
4_ Create machine learning object, usually a classifier or a regressor.
5_ Fit the Model
6_ Predict
7_ Evaluate the Model

Incorporating steps 1-6 into a pipeline helps to evaluate multiple machine learning algorithms at once for a side-by-side comparison in step 7.
___

You can use the editor on GitHub to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

## Stand-alone Projects

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for
- ETL Pipeline

- Data Science.
  [Short Term Rentals in San Francisco](https://github.com/ycheung8/de_portfolio/blob/main/notebook/notebook_SanFranciscoShortTermRentals.ipynb/)

- A
- B
- C
```markdown
Syntax highlighted code block

Fastest way to do a row count (through command line)
(1) Install GNUWIN, into a drive other than the C drive. 
   (for example, I installed onto the G drive)

(2) PATH=G:\ycheung\GnuWin32\bin;%PATH%

(3) Navigate to the directory location of the csv file

(4) gzip -f -9 Cohort_Waterfall_Aimovig_Migraine_Jan052022.csv
   (9 is the highest compression, 6 is the default, this replaces csv with csv.gz)

(5) count rows in original csv file using CMD
    find /v /c "" Cohort_Waterfall_Aimovig_Migraine_Jan052022_error.csv.csv
    
## Links
LinkedIn - Yi Cheung | https://www.linkedin.com/in/yi-cheung
