USE [FCEBCyberScorecard]
GO
DROP PROCEDURE IF EXISTS [dbo].[insFISMA_CIO_Metric_Staging_FY23_Q2]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[insFISMA_CIO_Metric_Staging_FY23_Q2]
(
@LastModifiedBy VARCHAR(100)
)
AS
------------------------------------------------------------------------

--EXEC [FCEBCyberScorecard].[dbo].[insFISMA_CIO_Metric_Staging_FY23_Q2] 'Gregory L. Grattan'

/*----------------------------------------------------------------------------------------------------
Creation Date = 07/06/2023 By Gregory L. Grattan

Description: Populates the [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging] For FY23 Q2

Changes:

07/05/2023 - G.Grattan - Added IdentifierText Column to Final Insert
07/12/2023 - G.Grattan - Added @MaxLastModifiedDate & 10.4-10.7 Answer Hours UPDATE Sections
07/18/2023 - G.Grattan - Updated QuestionID Column Population Method
08/17/2023 - G.Grattan - Added UPDATE Section to blank Answer records that = 'X'
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
SET @spReportingQuarter = 02 
SET @spLastModifiedBy = @LastModifiedBy 
------------------------------------------------------------------------
--DELETE STATEMENT
DELETE F
FROM [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging] F WITH(NOLOCK)
WHERE f.Reporting_Year = @spReportingYear
AND f.Reporting_Quarter = @spReportingQuarter
------------------------------------------------------------------------
--POPULATE FIRST FOUR QUESTIONS DATA
DECLARE @tmpFirstFour TABLE 
(
	 Breakout VARCHAR(250)
	,Breakout1 VARCHAR(250)
	,Breakout2 VARCHAR(5)
	,AgencyOperated INT
	,ContractorOperated INT
	,SecurityATO INT
	,Systems_In_Ongoing_Authorization INT
)
INSERT INTO @tmpFirstFour
SELECT 
 Breakout = ff.Breakout
,Breakout1 = RTRIM(LEFT(ff.Breakout, CHARINDEX(RIGHT(ff.Breakout,4), ff.Breakout) - 1))
,Breakout2 = PARSENAME(REPLACE(ff.Breakout, '- ', '.'), 1)
,AgencyOperated = ff.[Agency Operated]
,ContractorOperated = ff.[Contractor Operated]
,SecurityATO = ff.[Security ATO]
,Systems_In_Ongoing_Authorization = ff.[Systems in Ongoing Authorization]
FROM [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_FirstFour_Staging] ff WITH(NOLOCK)
------------------------------------------------------------------------
--UNPIVOT DATA
DECLARE @tmpUnpivot TABLE 
(
	 Agency VARCHAR(250)
	,Breakout2 VARCHAR(5)
	,Attribute VARCHAR(100)
	,Value INT
	,Question1 VARCHAR(10)
	,Question2 VARCHAR(5)
	,IdentifierText VARCHAR(50)	
	,IdentifierText2 VARCHAR(50)
)
INSERT INTO @tmpUnpivot
SELECT 
 Agency = Breakout1
,Breakout2
,Attribute
,Value
,Question1 = CASE Attribute WHEN 'AgencyOperated' THEN '1.1.1'
							WHEN 'ContractorOperated' THEN '1.1.2'
							WHEN 'SecurityATO' THEN '1.1.3'
							WHEN 'Systems_In_Ongoing_Authorization' THEN '1.1.4'
																				  ELSE NULL
END 
,Question2 = CASE Breakout2 WHEN 'H' THEN 'a'
							  WHEN 'M' THEN 'b'
							  WHEN 'L' THEN 'c'
												 ELSE NULL
END 
,IdentifierText = NULL
,IdentifierText2 = NULL
FROM @tmpFirstFour FF
UNPIVOT 
(Value FOR Attribute IN (ff.AgencyOperated, ff.ContractorOperated, ff.SecurityATO, ff.Systems_In_Ongoing_Authorization)) UnpivotTable
------------------------------------------------------------------------
--POPULATE IdentifierText COLUMNS
UPDATE F
SET
F.IdentifierText = REPLACE(REPLACE(REPLACE(REPLACE(CONCAT(F.Question1, '.', F.Question2), '.', ''), 'a', '1'), 'b', '2'), 'c', '3')
,F.IdentifierText2 = CONCAT(F.Question1, '.', F.Question2)
FROM @tmpUnpivot F 
------------------------------------------------------------------------
--FINAL SELECT FOR INSERT INTO TABLE
INSERT INTO [FCEBCyberScorecard].[Cyber].[FISMA_CIO_Metric_Staging]
SELECT 
 Reporting_Year = @spReportingYear
,Reporting_Quarter = @spReportingQuarter 
,CyberScope_Agency_ID = a.CyberScopePK_Agency
,Question_ID = @spReportingYear  + '_' + '01_' + f.IdentifierText --Q's From FY23Q1
,Identifier_Text = f.IdentifierText2
,Answer = CONVERT(VARCHAR(250), f.Value)
,Last_Modified_Date = GETDATE()
,Last_Modified_By = @spLastModifiedBy
FROM @tmpUnpivot F 
INNER JOIN [FCEBCyberScorecard].[db_owner].[tblCyberScopeAgencies] a WITH(NOLOCK) 
ON f.Agency = a.Agency
UNION ALL 
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
DROP TABLE [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_FirstFour_Staging]
DROP TABLE [FCEBCyberScorecard].[cyber].[FISMA_CIO_Metric_AllOthers_Staging]
------------------------------------------------------------------------
END 
