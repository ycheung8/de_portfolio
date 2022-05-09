--- THE TABLE: BMI_SAMPLE_TABLE HAS THE TEST CASES, TEST PATIENTS WITH TEST BMI VALUES. SELECT * FROM BMI_SAMPLE_TABLE;

/******************************************************************
/* STEP 1. CALCULATE THE INCREMENT, THIS IS USED IN A LATER FORMULA. */


MERGE INTO REGISTRY 
USING
(
WITH CALC_INCREMENT AS (
SELECT  COHORT.PROXY_MRN
      , COHORT.DOB
      , COHORT.GENDER
      , COHORT.LASTBMI
      , (MONTHS_BETWEEN(COHORT.LASTBMI, COHORT.DOB) - FLOOR(MONTHS_BETWEEN(COHORT.LASTBMI, COHORT.DOB) + 0.5) + 0.5 ) AS INCRE-- SELECT ( AGEINMONTHS - FLOOR( AGEINMONTHS + 0.5) + 0.5 )
      , MONTHS_BETWEEN(COHORT.LASTBMI, COHORT.DOB) AS AGEINMONTHS
      , CASE    WHEN ( (MONTHS_BETWEEN(COHORT.LASTBMI, COHORT.DOB)) > 240.5 )    -- 20.04 YEARS OLD
                THEN 1
                ELSE 0
                END  ABOVE_AGE_LIMIT
      , CASE    WHEN ( (MONTHS_BETWEEN(COHORT.LASTBMI, COHORT.DOB)) < 23.5  )    -- 1.96  YEARS OLD
                THEN 1
                ELSE 0
                END  BELOW_AGE_LIMIT                                                          
      , BMIVALUE
      , PERIOD
      
FROM (  SELECT  PROXY_MRN
               ,DOB
               ,GENDER
               ,LASTBMI
               ,BMIVALUE
               ,LASTOFFICEVISIT
               ,LASTMEDICAL
               ,ROW_NUMBER() OVER (PARTITION BY PROXY_MRN, PERIOD ORDER BY LASTMEDICAL DESC) AS SEQ
               ,PERIOD
               ,BMIELIGIBLE
               
        FROM    REGISTRY 
        WHERE   BMIVALUE IS NOT NULL
          AND   CURRENT_PERIOD IN (-1,0)
     ) COHORT

WHERE COHORT.SEQ IN (1)
)
,
/******************************************************************
/* STEP 2. CALCULATE THE Z-SCORE */
CALC_ZSCORE AS (

SELECT  PROXY_MRN
      , DOB
      , INCRE
      , AGEINMONTHS
      , GENDER
      , LASTBMI
      , BMIVALUE
      , ABOVE_AGE_LIMIT
      , BELOW_AGE_LIMIT
      , ROUND(( (POWER( (BMIVALUE/MVALUE),LVALUE )-1)/(LVALUE*SVALUE) ),2) AS ZSCORE
      , PERIOD
FROM    
(
-- BEGIN INNER QUERY TO FIND LMS SCORE
    SELECT   STEP1.PROXY_MRN
           , STEP1.DOB
           , STEP1.GENDER
           , STEP1.INCRE
           , STEP1.AGEINMONTHS
           , STEP1.ABOVE_AGE_LIMIT
           , STEP1.BELOW_AGE_LIMIT
           , LASTBMI
           , STEP1.BMIVALUE
           ,( (LMS1.L * INCRE) + ((1 - INCRE)*LMS2.L ) ) AS LVALUE      -- L: VALUE/LAMBDA SHOULD ALWAYS BE NEGATIVE
           ,( (LMS1.M * INCRE) + ((1 - INCRE)*LMS2.M ) ) AS MVALUE      -- M: MU
           ,( (LMS1.S * INCRE) + ((1 - INCRE)*LMS2.S ) ) AS SVALUE      -- S: COEFFICIENT OF VARIATION
           , PERIOD

    FROM    CALC_INCREMENT STEP1

    LEFT OUTER JOIN BMI_FORAGE LMS1 ON ( LMS1.AGEINMONTHS >= STEP1.AGEINMONTHS 
                                            AND  LMS1.AGEINMONTHS <  (STEP1.AGEINMONTHS + 1) 
                                            AND  STEP1.GENDER = LMS1.GENDER )
                                       
    LEFT OUTER JOIN BMI_FORAGE LMS2 ON ( LMS2.AGEINMONTHS >= (STEP1.AGEINMONTHS - 1) 
                                            AND  LMS2.AGEINMONTHS <  (STEP1.AGEINMONTHS ) 
                                            AND  STEP1.GENDER = LMS2.GENDER )

) FINDLMS
) -- END OF CTE
-- CALCULATE PERCENTILE
/******************************************************************
/* STEP 3. FIND THE PERCENTILE FROM THE Z-SCORE */
--FIND_PERCENTILE FROM NORMAL DISTRIBUTION TABLE
SELECT          CZ.*
               ,CASE    WHEN   CZ.ZSCORE <= -3.09     THEN   0.1
                        WHEN   CZ.ZSCORE  >= 3.09     THEN   99.9
                                                      ELSE   ND.PERCENTILE 
                                                      END    AS BMI_PERC
FROM            CALC_ZSCORE CZ
LEFT OUTER JOIN PCMH.MSHP_NORMAL_DIST ND ON (    CZ.ZSCORE >= ND.Z
                                         AND     CZ.ZSCORE < (ND.Z + 0.01)  
                                            )
                                            

) BMICALC ON (  REGISTRY.PROXY_MRN = BMICALC.PROXY_MRN 
          AND   REGISTRY.PERIOD = BMICALC.PERIOD )
WHEN MATCHED THEN UPDATE SET REGISTRY.BMI_PERC = BMICALC.BMI_PERC
                            ,REGISTRY.ABOVE_BMI_AGE_LIMIT = BMICALC.ABOVE_AGE_LIMIT
                            ,REGISTRY.BELOW_BMI_AGE_LIMIT = BMICALC.BELOW_AGE_LIMIT
                            ,REGISTRY.ZSCORE              = BMICALC.ZSCORE
;
COMMIT;

MERGE INTO REGISTRY COHORT
USING
(
SELECT  PROXY_MRN
      , DOB
      , GENDER
      , LASTBMI
      , PERIOD
      , BMIVALUE
      , BMI_PERC
                -- BMI CLASSIFICATIONS FOR AGE 2 TO 20 YEARS OLD 
      ,CASE    WHEN BMI_PERC IS NOT NULL
                    THEN 
                        CASE WHEN BMI_PERC >= 95    THEN 'OBESITY'
                             WHEN BMI_PERC >= 85    THEN 'OVERWEIGHT'
                             WHEN BMI_PERC >= 5     THEN 'HEALTHY WEIGHT'
                             WHEN BMI_PERC >= 0     THEN 'UNDERWEIGHT'
                        END
                    ELSE 
                -- BMI CLASSIFICATIONS FOR ADULTS >= AGE 20.04
                        CASE WHEN (BMI_PERC IS NULL AND ABOVE_AGE_LIMIT IN (1))
                             THEN
                                CASE WHEN BMIVALUE >= 30    THEN 'OBESITY'
                                     WHEN BMIVALUE >= 25    THEN 'OVERWEIGHT'
                                     WHEN BMIVALUE >= 18.5  THEN 'HEALTHY WEIGHT'
                                     WHEN BMIVALUE >= 0     THEN 'UNDERWEIGHT'
                                END             
                        END 
        END WGT_CLASS

FROM    REGISTRY    
) PERC ON (COHORT.PROXY_MRN = PERC.PROXY_MRN AND COHORT.PERIOD = PERC.PERIOD)
WHEN MATCHED THEN UPDATE SET COHORT.BMI_PERC    = PERC.BMI_PERC
                            ,COHORT.WGT_CLASS   = PERC.WGT_CLASS;
COMMIT;

UPDATE  REGISTRY
SET     OBESITYFLAG = 1
WHERE   WGT_CLASS = 'OBESITY'
;
COMMIT;

UPDATE  REGISTRY
SET     OVERWEIGHTFLAG = 1
WHERE   WGT_CLASS = 'OVERWEIGHT'
;
COMMIT;
UPDATE  REGISTRY
SET     HEALTHYWEIGHTFLAG = 1
WHERE   WGT_CLASS = 'HEALTHY WEIGHT'
;
COMMIT;
UPDATE  REGISTRY
SET     UNDERWEIGHTFLAG = 1
WHERE   WGT_CLASS = 'UNDERWEIGHT'
;
COMMIT;

SELECT  PROXY_MRN
      , DOB
      , TRUNC(MONTHS_BETWEEN(LASTBMI, DOB)/12)
      , LASTBMI
      , BMIVALUE
      , WGT_CLASS
FROM REGISTRY
WHERE TRUNC(MONTHS_BETWEEN(LASTBMI, DOB)/12) < 21


SELECT SUM(OBESITYFLAG), SUM(OVERWEIGHTFLAG), SUM(HEALTHYWEIGHTFLAG), SUM(UNDERWEIGHTFLAG) FROM REGISTRY WHERE CURRENT_PERIOD IN (-1,0)
-- WGT_CLASS
-- OBESITYFLAG
-- OVERWEIGHTFLAG
-- HEALTHYWEIGHTFLAG
-- UNDERWEIGHTFLAG


/* BELOW IS A FUNCTION I FOUND ONLINE FOR REPLICATING THE NORMAL DISTRIBUTION BASED ON Z-SCORE 
CREATE OR REPLACE FUNCTION tt_1(

    x BINARY_DOUBLE)

  RETURN BINARY_DOUBLE

AS

  b1 BINARY_DOUBLE := 0.319381530;

  b2 BINARY_DOUBLE := -0.356563782;

  b3 BINARY_DOUBLE := 1.781477937;

  b4 BINARY_DOUBLE := -1.821255978;

  b5 BINARY_DOUBLE := 1.330274429;

  p BINARY_DOUBLE  := 0.2316419;

  c BINARY_DOUBLE  := 0.39894228;

  t BINARY_DOUBLE;

BEGIN

  IF(x >= 0.0) THEN

    t  := 1.0   / ( 1.0 + p * x );

    RETURN (1.0 - c * exp( -x * x / 2.0 ) * t * ( t *( t * ( t * ( t * b5 + b4

    )           + b3 ) + b2 ) + b1 ));

  ELSE

    t := 1.0   / ( 1.0 - p * x );

    RETURN ( c * exp( -x * x / 2.0 ) * t * ( t *( t * ( t * ( t * b5 + b4 ) +

    b3 )       + b2 ) + b1 ));

  END IF;

END;

select tt_1(  z-score ) from dual;
*/

