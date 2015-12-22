SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxrda_vwFetch_sp]
(
	@rowsrequested		smCounter = 1,
	@company_id                  	smCompanyID,
	@trx_ctrl_num                	smControlNumber
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE	@MSKtrx_ctrl_num	smControlNumber
DECLARE	@MSKcompany_id	smCompanyID
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	company_id	smallint	NULL,
	trx_ctrl_num	char(16)	NULL,
	co_trx_id	int	NULL,
	trx_type	tinyint	NULL,
	last_modified_date	datetime	NULL,
	modified_by	int	NULL,
	apply_date	datetime	NULL,
	from_code	char(16)	NULL,
	to_code	char(16)	NULL,
	group_code	char(16)	NULL,
	from_org_id	varchar(30)	NULL,		
	to_org_id	varchar(30)	NULL		
)
 
SELECT	@rowsfound	= 0
SELECT	@MSKtrx_ctrl_num	= @trx_ctrl_num
SELECT	@MSKcompany_id	= @company_id
 
IF EXISTS (SELECT * FROM amtrxrda_vw
			WHERE	company_id	= @MSKcompany_id
			AND		trx_ctrl_num	= @MSKtrx_ctrl_num)
BEGIN
 
WHILE @MSKtrx_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		company_id,
		trx_ctrl_num,
		co_trx_id,
		trx_type,
		last_modified_date,
		modified_by,
		apply_date,
		from_code,
		to_code,
		group_code,
		from_org_id,		
		to_org_id			
	FROM	amtrxrda_vw
	WHERE		company_id = @MSKcompany_id
	AND		trx_ctrl_num = @MSKtrx_ctrl_num
 
	SELECT	@rowsfound = @rowsfound + @@rowcount
 
	SELECT @MSKtrx_ctrl_num	= MIN(trx_ctrl_num)
	FROM amtrxrda_vw
	WHERE	company_id = @MSKcompany_id
	AND	trx_ctrl_num	> @MSKtrx_ctrl_num
END
SELECT @MSKcompany_id	= MIN(company_id)
FROM	amtrxrda_vw
WHERE	company_id > @MSKcompany_id
 
WHILE @MSKcompany_id IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
	SELECT	@MSKtrx_ctrl_num	= MIN(trx_ctrl_num)
	FROM	amtrxrda_vw
	WHERE	company_id	= @MSKcompany_id
 
	WHILE @MSKtrx_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN
 
		INSERT INTO #temp
		SELECT
			timestamp,
			company_id,
			trx_ctrl_num,
			co_trx_id,
			trx_type,
			last_modified_date,
			modified_by,
			apply_date,
			from_code,
			to_code,
			group_code,
			from_org_id,		
			to_org_id			
		FROM	amtrxrda_vw
		WHERE		company_id = @MSKcompany_id
		AND		trx_ctrl_num = @MSKtrx_ctrl_num
 
		SELECT	@rowsfound = @rowsfound + @@rowcount
 
 
		SELECT	@MSKtrx_ctrl_num	= MIN(trx_ctrl_num)
		FROM	amtrxrda_vw
		WHERE	company_id = @MSKcompany_id
		AND		trx_ctrl_num	> @MSKtrx_ctrl_num
	END
 
	SELECT @MSKcompany_id	= MIN(company_id)
	FROM amtrxrda_vw
	WHERE	company_id	> @MSKcompany_id
END
END
SELECT
	timestamp,
	company_id,
	trx_ctrl_num,
	co_trx_id,
	trx_type,
	last_modified_date = convert(char(8),last_modified_date, 112),
	modified_by,
	apply_date = convert(char(8),apply_date, 112),
	from_code,
	to_code,
	group_code,
	from_org_id,			
	to_org_id				
FROM	#temp
ORDER BY	company_id, trx_ctrl_num
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxrda_vwFetch_sp] TO [public]
GO
