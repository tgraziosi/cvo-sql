SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/ 

CREATE PROCEDURE [dbo].[TransferCOASIntegration]
AS

BEGIN TRANSACTION

CREATE TABLE #TEMPCoas
	(
	guid VARCHAR(50) NOT NULL,
	account_code VARCHAR(32) NOT NULL,
	account_description VARCHAR(40) NOT NULL,
	reference_type VARCHAR(8) NULL,
	reference_code VARCHAR(32) NULL,
	reference_description VARCHAR(40) NULL,
	active_date INTEGER NULL,
	inactive_date INTEGER NULL,
	status VARCHAR(1) NOT NULL
	)

ALTER TABLE #TEMPCoas 
ADD CONSTRAINT TEMP2cont_index2 DEFAULT (NEWID()) FOR guid

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code, reference_type)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)


CREATE TABLE #TEMPCoasDeleted
	(
	guid VARCHAR(50) NOT NULL,
	account_code VARCHAR(30) NOT NULL,
	account_description VARCHAR(40) NOT NULL,
	reference_code VARCHAR(32) NULL,
	)

ALTER TABLE #TEMPCoasDeleted 
ADD CONSTRAINT TEMP3cont_index2 DEFAULT (NEWID()) FOR guid

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoasDeleted (guid)

DECLARE @DATETIME DATETIME
SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type, REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND EXISTS (SELECT 1 FROM glref_proc RPROC WHERE REF.reference_code LIKE RPROC.ref_code_mask)
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
		AND ACT.reference_flag IN (2,3)
		AND REF.status_flag = 0
ORDER BY CHRT.account_code
		


--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND ACT.reference_flag IN (1,2)
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
--ORDER BY CHRT.account_code


--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date, 'I'
FROM glchart CHRT
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND NOT EXISTS (SELECT 1 FROM glratyp TYP WHERE CHRT.account_code LIKE TYP.account_mask)
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)

--------------------------------------------------------------GET ACCOUNTS PREVIOUSLY DELETED------
INSERT #TEMPCoasDeleted (account_code, account_description,	reference_code)
SELECT COAS.account_code, COAS.account_description, COAS.reference_code
FROM glchart_history HIST
	INNER JOIN #TEMPCoas COAS ON HIST.account_code = COAS.account_code AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

--------------------------------------------------------------CHNAGE STATUS FOR ALL ACCOUNT PREVIOUSLY DELETED------
UPDATE HIST
	SET HIST.status = 'I',
		HIST.account_description = COAS.account_description
FROM glchart_history HIST, #TEMPCoasDeleted COAS
WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

DELETE COAS
FROM #TEMPCoas COAS, #TEMPCoasDeleted DEL
WHERE COAS.account_code = DEL.account_code AND ISNULL(COAS.reference_code,'') = ISNULL(DEL.reference_code,'')


--------------------------------------------------------------INSERT ACCOUNTS------
INSERT glchart_history (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT 	account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status 
FROM #TEMPCoas

DROP TABLE #TEMPCoas
DROP TABLE #TEMPCoasDeleted


COMMIT TRANSACTION

GO
GRANT EXECUTE ON  [dbo].[TransferCOASIntegration] TO [public]
GO
