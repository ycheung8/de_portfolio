Data Science Portfolio by Yi Cheung
https://ycheung8.github.io/

# Building a Machine Learning Pipeline

## Introduction

-	A machine learning pipeline orchestrates the flow of data into, and output from a machine learning model(s). 
-	Each component of a pipeline is called a step. 
-	We’ll focus on two types of methods: transform() and fit().

## Outline of Machine Learning Steps

1_ Preprocess<br>
2_ Fill in Missing Values<br>
3_ Convert categorical values into numerical values<br>
4_ Scale or standardize the data<br>
4_ Create machine learning object, usually a classifier or a regressor.<br>
5_ Fit the Model<br>
6_ Predict<br>
7_ Evaluate the Model<br>

Incorporating steps 1-6 into a pipeline helps to evaluate multiple machine learning algorithms at once for a side-by-side comparison in step 7.

## Python Coding for the Machine Learning Steps    

<b>Convert categorical values into numerical values </br>
```
categorical_transformer = Pipeline(
    [
        ('imputer_cat', SimpleImputer(strategy = 'constant', fill_value = 'missing')),
        ('onehot', OneHotEncoder(handle_unknown = 'ignore'))
    ]
)
```

<b>Impute Missing Values from Numerical Columns</b>
```
numerical_col = ["latitude","longitude","bathrooms","bedrooms","minimum_nights"]

numeric_transformer = Pipeline(
    [
        ('imputer_num', SimpleImputer(strategy = 'median')),
        ('scaler', StandardScaler())
    ]
)
```
___

### Links
LinkedIn - Yi Cheung | https://www.linkedin.com/in/yi-cheung
