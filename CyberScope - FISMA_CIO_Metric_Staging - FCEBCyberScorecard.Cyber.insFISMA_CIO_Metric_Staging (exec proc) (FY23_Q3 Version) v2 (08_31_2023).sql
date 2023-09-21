USE [FCEBCyberScorecard]
GO
DROP PROCEDURE IF EXISTS [dbo].[insFISMA_CIO_Metric_Staging_FY23_Q3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[insFISMA_CIO_Metric_Staging_FY23_Q3]
(
@LastModifiedBy VARCHAR(100)
)
AS
------------------------------------------------------------------------

--EXEC [FCEBCyberScorecard].[dbo].[insFISMA_CIO_Metric_Staging_FY23_Q3] 'Gregory L. Grattan'

/*----------------------------------------------------------------------------------------------------
Creation Date = 07/06/2023 By Gregory L. Grattan

Description: Populates the [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging] For FY23 Q3

Changes:

07/05/2023 - G.Grattan - Added IdentifierText Column to Final Insert
07/18/2023 - G.Grattan - Updated QuestionID Column Population Method
08/17/2023 - G.Grattan - Added Specific Section for FY23 Q3 that Insert Records From the CyberScope MFA and Encryption, Bureau and Component Level Data 
08/29/2023 - G.Grattan - Updated The CyberScope MFA and Encryption, Bureau and Component Level Data INSERT SECTION To Be A/B/C Instead of H/M/L
08/29/2023 - G.Grattan - Added Section to Sum MFA AND Encryption Data at Contractor and Federal Device Level to be Overall
08/29/2023 - G.Grattan - Added UPDATE Section for 1.1.1/2/3/4 Question Records to Convert H/M/L to a/b/c to Match Previous Quarters
----------------------------------------------------------------------------------------------------*/
BEGIN 
------------------------------------------------------------------------
--NEED DEBUG MESSAGES 
------------------------------------------------------------------------
--DECLARE & SET PARAMS 
DECLARE @spReportingYear VARCHAR(4)  
DECLARE @spReportingQuarter VARCHAR(2)  
DECLARE @spLastModifiedBy VARCHAR(100)

SET @spReportingYear = 2023 
SET @spReportingQuarter = 03 
SET @spLastModifiedBy = @LastModifiedBy 
------------------------------------------------------------------------
--DELETE STATEMENT
DELETE F
FROM [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging] F WITH(NOLOCK)
WHERE f.Reporting_Year = @spReportingYear
AND f.Reporting_Quarter = @spReportingQuarter
------------------------------------------------------------------------
--CREATE TEMP DATA SET TO SUM MFA AND ENCRYPTION CONTRACTOR AND FEDERAL DEVICE DATA TO OVERALL
--THIS DATA IS AT BUREAU LEVEL SO THERE ARE MULTIPLE RECORDS PER AGENCY
DECLARE @tmpMFA_Encryption TABLE --08/29/2023 ADD
(
 CyberScope_Agency_ID INT
,Identifier_Text VARCHAR(20)
,Answer FLOAT
)
INSERT INTO @tmpMFA_Encryption
SELECT 
CyberScope_Agency_ID = a.CyberScopePK_Agency
,Identifier_Text = CASE WHEN s.identifier_text LIKE '2.1.a%' THEN '2.1.a' 
						WHEN s.identifier_text LIKE '2.1.b%' THEN '2.1.b' 
						WHEN s.identifier_text LIKE '2.1.c%' THEN '2.1.c' 
						WHEN s.identifier_text LIKE '2.1.1.a%' THEN '2.1.1.a' 
						WHEN s.identifier_text LIKE '2.1.1.b%' THEN '2.1.1.b' 
						WHEN s.identifier_text LIKE '2.1.1.c%' THEN '2.1.1.c' 
						WHEN s.identifier_text LIKE '2.2.a%' THEN '2.2.a' 
						WHEN s.identifier_text LIKE '2.2.b%' THEN '2.2.b' 
						WHEN s.identifier_text LIKE '2.2.c%' THEN '2.2.c' 
						WHEN s.identifier_text LIKE '2.3.a%' THEN '2.3.a' 
						WHEN s.identifier_text LIKE '2.3.b%' THEN '2.3.b' 
						WHEN s.identifier_text LIKE '2.3.c%' THEN '2.3.c' 
						WHEN s.identifier_text LIKE '2.4.a%' THEN '2.4.a' 
						WHEN s.identifier_text LIKE '2.4.b%' THEN '2.4.b' 
						WHEN s.identifier_text LIKE '2.4.c%' THEN '2.4.c' 
END
,Answer = SUM(CONVERT(FLOAT,s.Answer))

FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_AllOthers_Staging] s WITH(NOLOCK)

LEFT JOIN [FCEBCyberScorecard].[db_owner].[tblCyberScopeAgencies] a WITH(NOLOCK) 
 ON s.Component = a.Agency

WHERE 
(  s.Identifier_Text LIKE '2.1.%'
OR s.identifier_text LIKE '2.2.%' 
OR s.identifier_text LIKE '2.3.a%' 
OR s.identifier_text LIKE '2.3.b%' 
OR s.identifier_text LIKE '2.3.c%' 
OR s.identifier_text LIKE '2.4%')
AND s.[Agency Size] = 'small'

GROUP BY 
a.CyberScopePK_Agency
,CASE WHEN s.identifier_text LIKE '2.1.a%' THEN '2.1.a' 
						WHEN s.identifier_text LIKE '2.1.b%' THEN '2.1.b' 
						WHEN s.identifier_text LIKE '2.1.c%' THEN '2.1.c' 
						WHEN s.identifier_text LIKE '2.1.1.a%' THEN '2.1.1.a' 
						WHEN s.identifier_text LIKE '2.1.1.b%' THEN '2.1.1.b' 
						WHEN s.identifier_text LIKE '2.1.1.c%' THEN '2.1.1.c' 
						WHEN s.identifier_text LIKE '2.2.a%' THEN '2.2.a' 
						WHEN s.identifier_text LIKE '2.2.b%' THEN '2.2.b' 
						WHEN s.identifier_text LIKE '2.2.c%' THEN '2.2.c' 
						WHEN s.identifier_text LIKE '2.3.a%' THEN '2.3.a' 
						WHEN s.identifier_text LIKE '2.3.b%' THEN '2.3.b' 
						WHEN s.identifier_text LIKE '2.3.c%' THEN '2.3.c' 
						WHEN s.identifier_text LIKE '2.4.a%' THEN '2.4.a' 
						WHEN s.identifier_text LIKE '2.4.b%' THEN '2.4.b' 
						WHEN s.identifier_text LIKE '2.4.c%' THEN '2.4.c' 
END
------------------------------------------------------------------------
--UPDATE H/M/L to be A/B/C on 1.1.1/2/3/4 Records
UPDATE ao --08/29/2023 UPDATE
SET
identifier_text = 
CASE WHEN ao.identifier_text LIKE '%H%' THEN REPLACE(ao.identifier_text, '(H)', '.a')
	 WHEN ao.identifier_text LIKE '%M%' THEN REPLACE(ao.identifier_text, '(M)', '.b')
	 WHEN ao.identifier_text LIKE '%L%' THEN REPLACE(ao.identifier_text, '(L)', '.c')
END 
FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_AllOthers_Staging] ao WITH(NOLOCK)
WHERE
(  ao.Identifier_Text LIKE '%H%'
OR ao.Identifier_Text LIKE '%M%'
OR ao.Identifier_Text LIKE '%L%')
------------------------------------------------------------------------
--FINAL SELECT FOR INSERT INTO TABLE
INSERT INTO [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging]
SELECT 
 Reporting_Year = LEFT(RIGHT(ao.rptPeriod, 7), 4)
,Reporting_Quarter = RIGHT(ao.rptPeriod, 1) 
,CyberScope_Agency_ID = a.CyberScopePK_Agency
,Question_ID = @spReportingYear  + '_' + '01_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ao.[identifier_text], '.', ''), 'a', '1'), 'b', '2'), 'c', '3'), 'd', '4'), 'iii', '03'), 'ii', '02'), 'i', '01') --Q's From FY23Q1
,Identifier_Text = ao.identifier_text
,Answer = ao.Answer
,Last_Modified_Date = GETDATE()
,Last_Modified_By = @spLastModifiedBy
FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_AllOthers_Staging] ao WITH(NOLOCK)
LEFT JOIN [FCEBCyberScorecard].[db_owner].[tblCyberScopeAgencies] a WITH(NOLOCK) 
 ON ao.Component = a.Agency
WHERE --08/29/2023 ADD
    ao.Identifier_Text NOT LIKE '2.1.%'
AND ao.Identifier_Text NOT LIKE '2.2.%'
AND ao.Identifier_Text NOT LIKE '2.3.a%'
AND ao.Identifier_Text NOT LIKE '2.3.b%'
AND ao.Identifier_Text NOT LIKE '2.3.c%'
AND ao.Identifier_Text NOT LIKE '2.4.%'
UNION ALL --08/29/2023 ADD
SELECT 
 Reporting_Year = @spReportingYear
,Reporting_Quarter = @spReportingQuarter 
,CyberScope_Agency_ID = M.CyberScope_Agency_ID
,Question_ID = @spReportingYear  + '_' + '03_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(M.[identifier_text], '.', ''), 'a', '1'), 'b', '2'), 'c', '3'), 'd', '4'), 'iii', '03'), 'ii', '02'), 'i', '01')  --Q's From FY23Q3
,Identifier_Text = M.identifier_text
,Answer = CONVERT(VARCHAR(20),M.Answer)
,Last_Modified_Date = GETDATE()
,Last_Modified_By = @spLastModifiedBy
FROM @tmpMFA_Encryption M
------------------------------------------------------------------------
------------------------------------------------------------------------
--CyberScope MFA and Encryption, Bureau and Component Level Data INSERT SECTION
--POPULATE MFA AND ENCRYPTION BUREAU AND COMPONENT LEVEL DATA
DECLARE @tmpBureauLevel TABLE 
(
	 Agency VARCHAR(100)
	,Bureau VARCHAR(25)
	,[2.1 (H)] FLOAT 
	,[2.1 (M)] FLOAT
	,[2.1 (L)] FLOAT
	,[2.1.1 (H)] FLOAT
	,[2.1.1 (M)] FLOAT
	,[2.1.1 (L)] FLOAT
	,[2.2 (H)] FLOAT
	,[2.2 (M)] FLOAT
	,[2.2 (L)] FLOAT
	,[2.3 (H)] FLOAT
	,[2.3 (M)] FLOAT
	,[2.3 (L)] FLOAT
	,[2.4 (H)] FLOAT
	,[2.4 (M)] FLOAT
	,[2.4 (L)] FLOAT
)
INSERT INTO @tmpBureauLevel
SELECT  
f.*
FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_MFAEncryption_BureauComponentLevel_Staging] f WITH(NOLOCK)
------------------------------------------------------------------------
--POPULATE ALL OF THE METRICS VERTICALLY USING A PIVOT
DECLARE @tmpBureauLevel_UnPivot TABLE 
(
 Agency VARCHAR(100)
,Bureau VARCHAR(25)
,Identifier_Text VARCHAR(25)
,Value FLOAT 
)
---------------------------------------------
--INSERT DATA INTO TEMP TABLE AFTER UNPIVOTING
INSERT INTO @tmpBureauLevel_UnPivot
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.a'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1 (H)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.b'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1 (M)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.c'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1 (L)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.1.a'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1.1 (H)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.1.b'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1.1 (M)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.1.1.c'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.1.1 (L)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.2.a'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.2 (H)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.2.b'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.2 (M)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.2.c'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.2 (L)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.3.a'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.3 (H)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.3.b'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.3 (M)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.3.c'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.3 (L)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.4.a'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.4 (H)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.4.b'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.4 (M)] )) UnpivotTable
UNION ALL 
SELECT 
 Agency
,Bureau
,Identifier_Text =  '2.4.c'
,Value
FROM @tmpBureauLevel b 
UNPIVOT (Value FOR Attribute IN (b.[2.4 (L)] )) UnpivotTable
---------------------------------------------
INSERT INTO [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging]
SELECT 
 Reporting_Year = @spReportingYear
,Reporting_Quarter = @spReportingQuarter 
,CyberScope_Agency_ID = a.CyberScopePK_Agency
,Question_ID = @spReportingYear  + '_' + '03_' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(up.[identifier_text], '.', ''), 'a', '1'), 'b', '2'), 'c', '3'), 'd', '4'), 'iii', '03'), 'ii', '02'), 'i', '01')
,Identifier_Text = up.Identifier_Text
,Answer = CONVERT(VARCHAR(250), up.Value)
,Last_Modified_Date = GETDATE()
,Last_Modified_By = @spLastModifiedBy
FROM @tmpBureauLevel_UnPivot up
LEFT JOIN [FCEBCyberScorecard].[db_owner].[tblCyberScopeAgencies] a WITH(NOLOCK) 
 ON up.Agency = a.Agency
------------------------------------------------------------------------
--CONVERT THE ANSWER FOR QUESTIONS 10.4, 10.5, 10.6, & 10.7 TO BE # OF HOURS
UPDATE S  
SET
s.Answer = 
CASE WHEN s.answer = '' OR s.answer = 'N/A' THEN '' ELSE
CONVERT(VARCHAR(50),(LTRIM(RTRIM(LEFT(RTRIM(LEFT(s.answer, CHARINDEX('Day', s.answer) - 0)), 2))) * 24)
+
ISNULL(CASE WHEN s.answer LIKE '%hour%' THEN LTRIM(RTRIM(RIGHT(RTRIM(LEFT(s.answer, CHARINDEX('hour', s.answer) - 1)), 2))) END, 0)
+ 
CONVERT(FLOAT, LTRIM(RTRIM(REPLACE(RIGHT(RTRIM(LEFT(s.answer, CHARINDEX('Minute', s.answer) - 0)), 4), 'm', '')))) / 60)
END 

FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_Staging] s WITH(NOLOCK)

WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(s.Question_ID, @spReportingYear, ''), @spReportingQuarter, ''), '_', ''), '(H)', ''), '(M)', ''), '(L)', '') >= 104
  AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(s.Question_ID, @spReportingYear, ''), @spReportingQuarter, ''), '_', ''), '(H)', ''), '(M)', ''), '(L)', '') <= 107
  AND s.Reporting_Quarter = @spReportingQuarter
  AND s.Reporting_Year = @spReportingYear
------------------------------------------------------------------------
--INSERT STAGING TABLE DATA INTO REPORTING TABLE
EXEC [FCEBCyberScorecard].[dbo].[insFISMA_CIO_Metric_Reporting] @spReportingYear, @spReportingQuarter, @spLastModifiedBy
------------------------------------------------------------------------
--DROP TEMP TABLES 
DROP TABLE [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_AllOthers_Staging]
DROP TABLE [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_MFAEncryption_BureauComponentLevel_Staging]
----------------------------------------------------------------------
END 
