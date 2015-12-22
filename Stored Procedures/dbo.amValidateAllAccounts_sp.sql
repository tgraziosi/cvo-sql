SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAllAccounts_sp] 
(
	@home_currency_code	smCurrencyCode,		
	@debug_level		smDebugLevel = 0	
)
AS 

DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@start_time 		datetime


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldacs.sp" + ", line " + STR( 153, 5 ) + " -- ENTRY: "

SELECT @start_time = GETDATE()






CREATE TABLE #amvldacs
(	
	account_code				char(32),		
	jul_apply_date				int,			
	invalid_flag				tinyint			
)




INSERT INTO #amvldacs
(
	account_code,
	jul_apply_date,
	invalid_flag
)
SELECT DISTINCT 
	new_account_code,
	jul_apply_date,
	1					
FROM #amaccts

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END


UPDATE 	#amvldacs
SET		invalid_flag 		= 0
FROM	#amvldacs tmp,
		glchart
WHERE	tmp.account_code 	= glchart.account_code 

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END

EXEC 	@result = amMoveBadAccounts_sp 
					20140,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END
	 


UPDATE 	#amvldacs
SET		invalid_flag = 1
FROM	#amvldacs tmp,
		glchart
WHERE	tmp.account_code		= glchart.account_code
AND		glchart.inactive_flag 	= 1  

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END

EXEC 	@result = amMoveBadAccounts_sp 
					20141,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END



UPDATE 	#amvldacs
SET		invalid_flag 			= 1
FROM	#amvldacs tmp,
		glchart
WHERE	tmp.account_code		= glchart.account_code
AND		glchart.inactive_flag	= 0 
AND		(
			glchart.active_date		<> 0
		OR 	glchart.inactive_date	<> 0
		)

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END

UPDATE 	#amvldacs
SET		invalid_flag 			= 0
FROM	#amvldacs tmp,
		glchart
WHERE	tmp.account_code		= glchart.account_code
AND		glchart.inactive_flag	= 0 
AND	
(	
	(			glchart.active_date 	<> 0
		AND		glchart.inactive_date	<> 0 
		AND		tmp.jul_apply_date		BETWEEN	glchart.active_date and glchart.inactive_date
	)
	OR
	(
				glchart.active_date 	= 0
		AND		glchart.inactive_date	<> 0 
		AND		tmp.jul_apply_date		< glchart.inactive_date
	)
	OR
	(
				glchart.active_date 	<> 0
		AND		glchart.inactive_date	= 0 
		AND		tmp.jul_apply_date		>= glchart.active_date
	)
)

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END

EXEC 	@result = amMoveBadAccounts_sp 
					20142,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END



UPDATE 	#amvldacs
SET		invalid_flag 			= 1
FROM	#amvldacs 	tmp,
		glchart		chart
WHERE	tmp.account_code		= chart.account_code
AND		chart.currency_code	 	!= @home_currency_code
AND		chart.currency_code 	!= ""

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END

EXEC 	@result = amMoveBadAccounts_sp 
					20149,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldacs
	RETURN @result
END


DROP TABLE #amvldacs






CREATE TABLE #amvldref
(	
	account_reference_code		varchar(32),	
	invalid_flag				tinyint			
)





CREATE TABLE #amvldarf
(	
	account_code				char(32),		
	account_reference_code		varchar(32),	
	invalid_flag				tinyint			
)





INSERT INTO #amvldref
(
	account_reference_code,	
	invalid_flag		 
)
SELECT DISTINCT
	account_reference_code,
	1
FROM	#amaccts 
WHERE	error_code 						= 0
AND	( LTRIM(account_reference_code) IS NOT NULL AND LTRIM(account_reference_code) != " " )

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END


UPDATE 	#amvldref
SET		invalid_flag						= 0
FROM	#amvldref tmp,
		glref
WHERE 	tmp.account_reference_code 			= glref.reference_code 

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20147, 
					1,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END


UPDATE 	#amvldref
SET		invalid_flag 						= 1
FROM	#amvldref tmp,
		glref
WHERE	tmp.account_reference_code 			= glref.reference_code 
AND		glref.status_flag					= 1 

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20146, 
					1,
					@debug_level

IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END





INSERT INTO #amvldarf
(
	account_code,			
	account_reference_code,	
	invalid_flag		 
)
SELECT DISTINCT
	accounts.new_account_code,
	accounts.account_reference_code,
	0
FROM	#amaccts accounts
WHERE	accounts.error_code 						= 0

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All account code, ref code pairs to be tested"
	SELECT * FROM #amvldarf
END

UPDATE 	#amvldarf
SET		invalid_flag 				= 1
FROM	#amvldarf 	tmp,
		glref		r,
		glrefact 	ra,
		glratyp		rat
WHERE	tmp.account_reference_code 	= r.reference_code
AND		r.reference_type 			= rat.reference_type
AND		ra.account_mask				= rat.account_mask
AND		tmp.account_code			LIKE	RTRIM(ra.account_mask)
AND		ra.reference_flag 			= 1 

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All account code excluded by the reference code as marked with true"
	SELECT * FROM #amvldarf
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20145, 
					0,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END


UPDATE 	#amvldarf
SET		invalid_flag 				= 1
FROM	#amvldarf 	tmp,
		glrefact	ra
WHERE	RTRIM(tmp.account_code)		LIKE	RTRIM(ra.account_mask)
AND		ra.reference_flag 			= 3 

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All accounts requiring reference codes are marked with true"
	SELECT * FROM #amvldarf
END

UPDATE 	#amvldarf
SET		invalid_flag 						= 0
FROM	#amvldarf 	tmp
WHERE	( LTRIM(tmp.account_reference_code) IS NOT NULL AND LTRIM(tmp.account_reference_code) != " " )
AND	invalid_flag						= 1

SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All accounts without reference codes are marked with false"
	SELECT * FROM #amvldarf
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20144, 
					0,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END


UPDATE 	#amvldarf
SET		invalid_flag 				= 1
FROM	#amvldarf 	tmp,
		glref		r,
		glrefact	ra
WHERE	tmp.account_code			LIKE	RTRIM(ra.account_mask)
AND		ra.reference_flag 			= 3 
AND		tmp.account_reference_code	= r.reference_code
AND		r.reference_type			NOT IN (SELECT 	reference_type 
											FROM 	glratyp rat
											WHERE	rat.account_mask = ra.account_mask)
SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All account codes with the wrong type of refence code are marked with true"
	SELECT * FROM #amvldarf
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20143, 
					0,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END
	

UPDATE 	#amvldarf
SET		invalid_flag 				= 1
FROM	#amvldarf 	tmp,
		glref		r,
		glrefact	ra
WHERE	tmp.account_code			LIKE	RTRIM(ra.account_mask)
AND		ra.reference_flag 			= 2 
AND		tmp.account_reference_code	= r.reference_code
AND		r.reference_type			NOT IN (SELECT 	reference_type 
											FROM 	glratyp rat
											WHERE	rat.account_mask = ra.account_mask)
SELECT @result = @@error
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END

IF @debug_level >= 3
BEGIN
	SELECT "All account code with the wrong optional reference codes are marked with true."
	SELECT * FROM #amvldarf
END

EXEC 	@result = amMoveBadAcctRefCodes_sp 
					20148, 
					0,
					@debug_level
IF @result <> 0
BEGIN
	DROP TABLE #amvldref
	DROP TABLE #amvldarf
	RETURN @result
END
	
	
DROP TABLE #amvldref
DROP TABLE #amvldarf

IF @debug_level >= 4
	SELECT time_taken = DATEDIFF(ms, @start_time, GETDATE())

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldacs.sp" + ", line " + STR( 694, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAllAccounts_sp] TO [public]
GO
