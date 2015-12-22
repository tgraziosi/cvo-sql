SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcfovrt.SPv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcfovrt_sp]
(
	@sub_id		smallint,
	@p_account	varchar(32),
	@date		int,
	@consol_type	smallint,
	@sub_home_cur	varchar(8)
)

AS


DECLARE @found tinyint, @not_found tinyint, @rate float, @rate_oper float, 
	@rate_type_OA smallint, @rate_type_OT smallint,
	@multi_currency_flag smallint 

SELECT @found = 1, @not_found = 0, @rate_type_OA = 7, @rate_type_OT = 8


SELECT	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date = @date
AND	currency_code = @sub_home_cur

IF @rate IS NOT NULL
BEGIN
	SELECT @found, @rate, @rate_oper, @rate_type_OA
	RETURN 0
END


SELECT 	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date = @date
AND	currency_code = @sub_home_cur

IF @rate IS NOT NULL
BEGIN
	SELECT @found, @rate, @rate_oper, @rate_type_OA
	RETURN 0
END


SELECT 	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 0
AND 	consol_type = @consol_type
AND 	date = @date
AND	currency_code = @sub_home_cur

IF @rate IS NOT NULL
BEGIN
	SELECT @found, @rate , @rate_oper, @rate_type_OT
	RETURN 0
END


SELECT 	@rate = override_rate,
	@rate_oper = ISNULL(override_rate_oper, 0.0)
FROM 	gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 0
AND 	consol_type = @consol_type
AND 	date = @date
AND	currency_code = @sub_home_cur

IF @rate IS NOT NULL
BEGIN
	SELECT @found, @rate , @rate_oper, @rate_type_OT
	RETURN 0
END

SELECT @not_found, null, null, null
RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcfovrt_sp] TO [public]
GO
