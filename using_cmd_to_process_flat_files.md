(1) Install GNUWIN, into a drive other than the C drive. 
   (for example, I installed onto the G drive)

(2) PATH=G:\ycheung\GnuWin32\bin;%PATH%

(3) Navigate to the directory location of the csv file

(4) 9 is the highest compression, 6 is the default, this replaces csv with csv.gz
```
gzip -f -9 Cohort_Waterfall.csv
```
(5) count rows in original csv file using CMD
```
find /v /c "" Cohort_Waterfall.csv
```
