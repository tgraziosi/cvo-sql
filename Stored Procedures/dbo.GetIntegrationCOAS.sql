SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[GetIntegrationCOAS] (@accountI as VARCHAR(32) = NULL, @accountF as VARCHAR(32) = NULL)
AS

BEGIN TRANSACTION

CREATE TABLE #TEMPCoas
	(
	guid VARCHAR(50) NOT NULL,
	account_code VARCHAR(32) NOT NULL,
	account_description VARCHAR(40) NOT NULL,
	reference_code VARCHAR(32) NULL,
	reference_description VARCHAR(40) NULL,
	seg1_code VARCHAR(40) NULL,
	seg2_code VARCHAR(40) NULL,
	seg3_code VARCHAR(40) NULL,
	seg4_code VARCHAR(40) NULL,
	status VARCHAR(1) NOT NULL,
	type INTEGER
	)

ALTER TABLE #TEMPCoas 
ADD CONSTRAINT fk_GetIntegrationCOAS DEFAULT (NEWID()) FOR guid

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)

DECLARE @iError NUMERIC
SET @iError = 0 

DECLARE @DATETIME DATETIME
SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)


--GET COMPANY


INSERT INTO #TEMPCoas (account_code, account_description, status, type)
SELECT company_id, company_name, 'I', 1
FROM glco

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION

	SET @iError = @@ERROR
END


--GET ACCOUNT DEFINITION


INSERT INTO #TEMPCoas (	account_code, account_description, seg1_code, seg2_code, seg3_code, seg4_code, status, type)
SELECT DEF.acct_format, DEF.description, DEF.start_col, DEF.length, DEF.acct_level, DEF.natural_acct_flag, 'I', 3
FROM glaccdef DEF

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION

	SET @iError = @@ERROR
END

IF @accountI = '' 
BEGIN 
	SET @accountI = NULL 
END 

IF @accountF = '' 
BEGIN 
	SET @accountF = NULL 
END


--GET ACCOUNT


IF ((CHARINDEX('%',ISNULL(@accountI,'')) = 0) OR (CHARINDEX('_',ISNULL(@accountI,'')) = 0 ))
BEGIN
	INSERT INTO #TEMPCoas (account_code, account_description, reference_code, reference_description, seg1_code, seg2_code, seg3_code, seg4_code, status, type)
	SELECT HIST.account_code, HIST.account_description, HIST.reference_code, HIST.reference_description, SEG1.short_desc, SEG2.short_desc, SEG3.short_desc, SEG4.short_desc, HIST.status, 2
	FROM glchart_history HIST
		INNER JOIN glchart CHRT ON HIST.account_code = CHRT.account_code
		LEFT JOIN glseg1 SEG1 ON CHRT.seg1_code = SEG1.seg_code
		LEFT JOIN glseg2 SEG2 ON CHRT.seg2_code = SEG2.seg_code
		LEFT JOIN glseg3 SEG3 ON CHRT.seg3_code = SEG3.seg_code
		LEFT JOIN glseg4 SEG4 ON CHRT.seg4_code = SEG4.seg_code
	WHERE HIST.status IN ('I','D','U') 
		AND @DATETIME BETWEEN 
					CASE HIST.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, HIST.active_date - 693596,'01/01/1900') END 
					AND 
					CASE HIST.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, HIST.inactive_date - 693596,'01/01/1900') END
		AND HIST.account_code BETWEEN ISNULL(@accountI,(SELECT MIN(account_code) FROM glchart_history))
						AND ISNULL(@accountF,(SELECT MAX(account_code) FROM glchart_history))
END
ELSE
BEGIN
	INSERT INTO #TEMPCoas (account_code, account_description, reference_code, reference_description, seg1_code, seg2_code, seg3_code, seg4_code, status, type)
	SELECT HIST.account_code, HIST.account_description, HIST.reference_code, HIST.reference_description, SEG1.short_desc, SEG2.short_desc, SEG3.short_desc, SEG4.short_desc, HIST.status, 2
	FROM glchart_history HIST
		INNER JOIN glchart CHRT ON HIST.account_code = CHRT.account_code
		LEFT JOIN glseg1 SEG1 ON CHRT.seg1_code = SEG1.seg_code
		LEFT JOIN glseg2 SEG2 ON CHRT.seg2_code = SEG2.seg_code
		LEFT JOIN glseg3 SEG3 ON CHRT.seg3_code = SEG3.seg_code
		LEFT JOIN glseg4 SEG4 ON CHRT.seg4_code = SEG4.seg_code
	WHERE status IN ('I','D','U') 
		AND @DATETIME BETWEEN 
					CASE HIST.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, HIST.active_date - 693596,'01/01/1900') END 
					AND 
					CASE HIST.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, HIST.inactive_date - 693596,'01/01/1900') END
		AND HIST.account_code LIKE @accountI AND HIST.account_code LIKE @accountF
END	

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION

	SET @iError = @@ERROR
END


UPDATE CHRT
	SET CHRT.status = 'T'
FROM glchart_history CHRT, #TEMPCoas TEMP
WHERE CHRT.account_code = TEMP.account_code
	AND ISNULL(CHRT.reference_code,'') = ISNULL(TEMP.reference_code,'')

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION

	SET @iError = @@ERROR
END


SELECT account_code, account_description, reference_code, reference_description, seg1_code, seg2_code, seg3_code, seg4_code, status, type
FROM #TEMPCoas

DROP TABLE #TEMPCoas

COMMIT TRANSACTION

GO
GRANT EXECUTE ON  [dbo].[GetIntegrationCOAS] TO [public]
GO
