SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxdpr_vwLastFilt_sp] 
( 
	@rowsrequested                  smallint = 1,
	@company_id_filter              smCompanyID, 
	@trx_ctrl_num_filter            smControlNumber 
) 
AS 

CREATE TABLE #temp 
( 
	timestamp 			varbinary(8) 	null,
	company_id 			smallint 		null,
	trx_ctrl_num 		char(16) 		null,
	co_trx_id 			int 			null,
	trx_type 			tinyint 		null,
	last_modified_date 	datetime 		null,
	modified_by 		int 			null,
	apply_date 			datetime 		null,
	posting_flag 		smallint 		null,
	date_posted 		datetime 		null,
	trx_description 	varchar(40) 	null,
	doc_reference 		varchar(40) 	null,
	process_id 			int 			null,
	from_code 			char(16) 		null,
	to_code 			char(16) 		null, 
	from_book 			char(16) 		null,
	to_book 			char(16) 		null,
	group_code			char(16)		null ,
	from_org_id			varchar(30)		null,		
	to_org_id			varchar(30)		null 		
)

DECLARE 
	@rowsfound 			smallint, 
	@MSKtrx_ctrl_num 	smControlNumber,
	@company_id			smCompanyID
	

SELECT @rowsfound = 0 

SELECT @company_id 	= @company_id_filter 

SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
FROM 	amtrxdpr_vw 
WHERE 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)
AND 	company_id 			= @company_id 

IF @MSKtrx_ctrl_num IS NULL 
BEGIN 
    DROP TABLE #temp 
    RETURN 
END 

INSERT 	INTO #temp 
SELECT 	 
	timestamp,
	company_id,
	trx_ctrl_num,
	co_trx_id,
	trx_type,
	last_modified_date, 
	modified_by,
	apply_date, 
	posting_flag,
	date_posted, 
	trx_description,
	doc_reference,
	process_id,
	from_code,
	to_code,
	from_book,
	to_book,
	group_code,
	from_org_id,					
	to_org_id				 		
FROM 	amtrxdpr_vw 
WHERE 	company_id 		= @company_id 		
AND 	trx_ctrl_num 	= @MSKtrx_ctrl_num 

SELECT @rowsfound = @@rowcount 

SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
FROM 	amtrxdpr_vw 
WHERE 	company_id 			= @company_id 
AND 	trx_ctrl_num 		< @MSKtrx_ctrl_num 
AND 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)

WHILE @MSKtrx_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested 
BEGIN 

	INSERT 	INTO #temp 
	SELECT 	 
			timestamp,
			company_id,
			trx_ctrl_num,
			co_trx_id,
			trx_type,
			last_modified_date, 
			modified_by,
			apply_date, 
			posting_flag,
			date_posted, 
			trx_description,
			doc_reference,
			process_id,
			from_code,
			to_code,
			from_book,
			to_book,
			group_code,
			from_org_id,					
			to_org_id				 		
	FROM 	amtrxdpr_vw 
	WHERE 	company_id 		= @company_id 
	AND 	trx_ctrl_num 	= @MSKtrx_ctrl_num 

	SELECT @rowsfound = @rowsfound + @@rowcount 

	 
	SELECT 	@MSKtrx_ctrl_num 	= MAX(trx_ctrl_num) 
	FROM 	amtrxdpr_vw 
	WHERE 	company_id 			= @company_id 
	AND 	trx_ctrl_num 		< @MSKtrx_ctrl_num 
 	AND 	trx_ctrl_num 		LIKE RTRIM(@trx_ctrl_num_filter)
END
 
SELECT 
	timestamp,
	company_id,
	trx_ctrl_num,
	co_trx_id,
	trx_type,
	last_modified_date 	= CONVERT(char(8), last_modified_date,112), 
	modified_by,
	apply_date 			= CONVERT(char(8), apply_date,112), 
	posting_flag,
	date_posted 		= CONVERT(char(8), date_posted,112), 
	trx_description,
	doc_reference,
	process_id,
	from_code,
	to_code,
	from_book,
	to_book,
	group_code,
	from_org_id,					
	to_org_id				 		
FROM #temp 
ORDER BY  company_id, trx_ctrl_num 

DROP TABLE #temp 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxdpr_vwLastFilt_sp] TO [public]
GO
