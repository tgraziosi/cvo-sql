SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ambookLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@book_code_filter 	smBookCode 
) 
AS 

CREATE TABLE #temp 
( 
	timestamp 					varbinary(8) 	null,
	book_code 					char(8) 		null,
	book_description 			varchar(40) 	null,
	capitalization_threshold 	float 			null,
	currency_code 				varchar(8) 		null,
	allow_revaluations 			tinyint 		null,
	allow_writedowns 			tinyint 		null,
	allow_adjustments 			tinyint 		null,
	suspend_depr 				tinyint 		null,
	post_to_gl 					tinyint 		null,
	gl_book_code 				varchar(8) 		null,
	depr_if_less_than_yr		tinyint 		null 
)

DECLARE @rowsfound smallint 
DECLARE @MSKbook_code smBookCode 

SELECT @rowsfound = 0 

SELECT 	@MSKbook_code 	= MAX(book_code) 
FROM 	ambook 
WHERE 	book_code 		LIKE RTRIM(@book_code_filter)

IF @MSKbook_code IS NULL 
BEGIN 
 DROP TABLE #temp 
 RETURN 
END 

INSERT 	INTO #temp 
SELECT 	 
		timestamp,
		book_code,
		book_description,
		capitalization_threshold,
		currency_code,
		allow_revaluations,
		allow_writedowns,
		allow_adjustments,
		suspend_depr,
		post_to_gl,
		gl_book_code,
		depr_if_less_than_yr 
FROM 	ambook 
WHERE 	book_code = @MSKbook_code 

SELECT @rowsfound = @@rowcount 

SELECT 	@MSKbook_code 	= MAX(book_code) 
FROM 	ambook 
WHERE 	book_code 		< @MSKbook_code 
AND 	book_code 		LIKE RTRIM(@book_code_filter)

WHILE @MSKbook_code IS NOT NULL AND @rowsfound < @rowsrequested 
BEGIN 

 	INSERT 	INTO #temp 
 	SELECT 	 
		timestamp,
		book_code,
		book_description,
		capitalization_threshold,
		currency_code,
		allow_revaluations,
		allow_writedowns,
		allow_adjustments,
		suspend_depr,
		post_to_gl,
		gl_book_code,
		depr_if_less_than_yr 
 	FROM 	ambook 
 	WHERE 	book_code = @MSKbook_code 

 	SELECT @rowsfound = @rowsfound + @@rowcount 

	 
	SELECT 	@MSKbook_code 	= MAX(book_code) 
	FROM 	ambook 
	WHERE 	book_code 		< @MSKbook_code 
 	AND 	book_code 		LIKE RTRIM(@book_code_filter)
END 

SELECT 
	timestamp,
	book_code,
	book_description,
	capitalization_threshold,
	currency_code,
	allow_revaluations,
	allow_writedowns,
	allow_adjustments,
	suspend_depr,
	post_to_gl,
	gl_book_code,
	depr_if_less_than_yr 
FROM 	#temp 
ORDER BY book_code 
DROP TABLE #temp 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[ambookLastFilt_sp] TO [public]
GO
