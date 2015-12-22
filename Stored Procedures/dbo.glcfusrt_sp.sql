SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcfusrt.SPv - e7.2.2 : 1.10
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcfusrt_sp]
(
	@sub_id		smallint = null,
	@p_account	varchar(32) = null,
	@date		int = null,
	@consol_type	smallint = null,
	@from_curr	varchar(8),
	@to_curr	varchar(8)
)
AS
DECLARE @found tinyint, @rate float, @not_found tinyint, @max_date int,
	@rate_oper float

SELECT	@found = 1, @rate = NULL 

SELECT	@max_date = MAX( date )		
FROM 	gltrrate	
WHERE 	sub_comp_id = @sub_id	
AND 	all_comp_flag = 0
AND 	record_type = 1	
AND 	account_code = @p_account
AND 	date <= @date		

SELECT	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date <= @date
AND		date = @max_date
AND	currency_code = @from_curr

IF	@rate IS NOT NULL
BEGIN	
	SELECT	@found, @rate, @rate_oper, NULL
	RETURN 0
END


SELECT	@max_date = MAX( date )
FROM 	gltrrate	
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 0	
AND 	consol_type = 6
AND 	date <= @date

SELECT	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 0
AND 	consol_type = 6
AND 	date <= @date
AND		date = @max_date
AND	currency_code = @from_curr

IF	@rate IS NOT NULL
BEGIN	
	SELECT	@found, @rate, @rate_oper, NULL
	RETURN 0
END


SELECT	@max_date = MAX( date )
FROM 	gltrrate	
WHERE 	all_comp_flag = 1
AND 	record_type = 1	
AND 	account_code = @p_account
AND 	date <= @date		

SELECT	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date <= @date
AND		date = @max_date
AND	currency_code = @from_curr

IF	@rate IS NOT NULL
BEGIN	
	SELECT	@found, @rate, @rate_oper, NULL
	RETURN 0
END


SELECT	@max_date = MAX( date )
FROM 	gltrrate	
WHERE 	all_comp_flag = 1
AND 	record_type = 0	
AND 	consol_type = 6
AND 	date <= @date

SELECT	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 0
AND 	consol_type = 6
AND 	date <= @date
AND		date = @max_date
AND	currency_code = @from_curr

IF	@rate IS NOT NULL
BEGIN	
	SELECT	@found, @rate, @rate_oper, NULL
	RETURN 0
END

SELECT	@not_found, NULL , NULL, NULL
RETURN 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcfusrt_sp] TO [public]
GO
