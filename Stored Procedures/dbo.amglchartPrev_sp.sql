SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglchartPrev_sp] 
( 
	@rowsrequested                  smallint = 1,
	@account_code                	varchar(32 )
) 
AS 

CREATE TABLE #temp
( 
	timestamp			 	varbinary(8) null,
	account_code 			varchar(32) null,
	account_description 	varchar(40) null,
	account_type 			smallint null,
	new_flag 				smallint null,
	seg1_code 				varchar(32) null,
	seg2_code 				varchar(32) null,
	seg3_code 				varchar(32) null,
	seg4_code 				varchar(32) null,
	consol_detail_flag 		smallint null,
	consol_type 			smallint null,
	active_date 			int null,
	inactive_date 			int null,
	inactive_flag 			smallint null,
	currency_code 			varchar(8) null,
	revaluate_flag 			smallint null 
)

DECLARE @rowsfound 			smallint 
DECLARE @MSKaccount_code 	varchar(32 )

SELECT @rowsfound = 0 
SELECT @MSKaccount_code = @account_code 

SELECT 	@MSKaccount_code 	= MAX(account_code) 
FROM 	am_glchart_root_vw 
WHERE 	account_code 		< @MSKaccount_code 
AND 	account_code 	in (select account_code from sm_accounts_access_vw)

WHILE @MSKaccount_code IS NOT NULL AND @rowsfound < @rowsrequested 
BEGIN 

	INSERT INTO #temp 
	SELECT 	
		timestamp,
		account_code,
		account_description,
		account_type,
		new_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		consol_detail_flag,
		consol_type,
		active_date,
		inactive_date,
		inactive_flag,
		currency_code,
		revaluate_flag 
	FROM 	glchart 
	WHERE 	account_code = @MSKaccount_code 

	SELECT @rowsfound = @rowsfound + @@rowcount 

	 
	SELECT 	@MSKaccount_code 	= MAX(account_code) 
	FROM 	glchart_root_vw 
	WHERE 	account_code 		< @MSKaccount_code 	
	AND	account_code 	in (select account_code from sm_accounts_access_vw)

END 

SELECT 
	timestamp,
	account_code,
	account_description,
	account_type,
	new_flag,
	seg1_code,
	seg2_code,
	seg3_code,
	seg4_code,
	consol_detail_flag,
	consol_type,
	active_date,
	inactive_date,
	inactive_flag,
	currency_code,
	revaluate_flag 
FROM #temp 
ORDER BY  account_code 
DROP TABLE #temp 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amglchartPrev_sp] TO [public]
GO
