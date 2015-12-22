SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amname_vwFirst_sp] 
( 
	@rowsrequested	smallint = 1 
) 
AS 

CREATE TABLE #temp 
(
	timestamp 				varbinary(8) 	null,
	company_id 				smallint 		null,
	addr1 					varchar(40) 	null,
	addr2 					varchar(40) 	null,
	addr3 					varchar(40) 	null,
	addr4 					varchar(40) 	null,
	addr5 					varchar(40) 	null,
	addr6 					varchar(40) 	null,
	ap_interface			tinyint			null,
	post_depreciation		tinyint 		null,
	post_additions			tinyint 		null,
	post_disposals			tinyint 		null,
	post_other_activities	tinyint 		null,
	last_modified_date 		datetime 		null,
	modified_by 			int 			null
)


DECLARE @rowsfound smallint, 
		@MSKcompany_id smCompanyID 

SELECT @rowsfound = 0 

SELECT 	@MSKcompany_id = MIN(company_id) 
FROM 	amname_vw 

IF @MSKcompany_id IS NULL 
BEGIN 
 DROP TABLE #temp 
 RETURN 
END 

INSERT 	INTO #temp 
SELECT 	 
 timestamp,
 company_id,
 addr1,
 addr2,
 addr3,
 addr4,
 addr5,
 addr6,
 ap_interface,
 post_depreciation,
 post_additions,
 post_disposals,
 post_other_activities,
	last_modified_date 	= CONVERT(char(8),last_modified_date, 112),
	modified_by
FROM 	amname_vw 
WHERE 	company_id = @MSKcompany_id 

SELECT @rowsfound = @@rowcount 

SELECT 	@MSKcompany_id 	= MIN(company_id) 
FROM 	amname_vw 
WHERE 	company_id 		> @MSKcompany_id 

WHILE @MSKcompany_id IS NOT NULL AND @rowsfound < @rowsrequested 
BEGIN 

	INSERT 	INTO #temp 
	SELECT 	 
 timestamp,
 company_id,
 addr1,
 addr2,
 addr3,
 addr4,
 addr5,
 addr6,
 ap_interface,
 post_depreciation,
 post_additions,
 post_disposals,
 post_other_activities,
		last_modified_date 	= CONVERT(char(8),last_modified_date, 112),
		modified_by
	FROM 	amname_vw 
	WHERE 	company_id = @MSKcompany_id 

	SELECT @rowsfound = @rowsfound + @@rowcount 
	
	 
	SELECT 	@MSKcompany_id 	= MIN(company_id) 
	FROM	amname_vw 
	WHERE 	company_id 		> @MSKcompany_id 
END 

SELECT 
	timestamp,
	company_id,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	ap_interface,
	post_depreciation,
	post_additions,
	post_disposals,
	post_other_activities,
	last_modified_date = convert(char(8),last_modified_date, 112),
	modified_by 
FROM #temp 
ORDER BY company_id 

DROP TABLE #temp 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amname_vwFirst_sp] TO [public]
GO
