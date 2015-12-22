SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[glcfovsp_sp]
(
	@sub_id		smallint,
	@p_account	varchar(32),
	@date		int,
	@consol_type	smallint,
	@overr_rate	float OUTPUT,
	@overr_rate_oper	float OUTPUT
)

AS


DECLARE @found tinyint, @not_found tinyint, @rate float, @rate_oper float

SELECT @found = 1, @not_found = 0


SELECT	@rate = override_rate, @rate_oper = override_rate_oper
FROM 	#gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date = @date

IF @rate IS NOT NULL
BEGIN
	SELECT @overr_rate = @rate, @overr_rate_oper = @rate_oper
	RETURN 0
END


SELECT 	@rate = override_rate, @rate_oper = override_rate_oper
FROM 	#gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 1
AND 	account_code = @p_account
AND 	date = @date

IF @rate IS NOT NULL
BEGIN
	SELECT @overr_rate = @rate, @overr_rate_oper = @rate_oper
	RETURN 0
END


SELECT 	@rate = override_rate, @rate_oper = override_rate_oper
FROM 	#gltrrate
WHERE 	sub_comp_id = @sub_id
AND 	all_comp_flag = 0
AND 	record_type = 0
AND 	consol_type = @consol_type
AND 	date = @date

IF @rate IS NOT NULL
BEGIN
	SELECT @overr_rate = @rate, @overr_rate_oper = @rate_oper
	RETURN 0
END


SELECT 	@rate = override_rate, @rate_oper = override_rate_oper
FROM 	#gltrrate
WHERE 	all_comp_flag = 1
AND 	record_type = 0
AND 	consol_type = @consol_type
AND 	date = @date

IF @rate IS NOT NULL
BEGIN
	SELECT @overr_rate = @rate, @overr_rate_oper = @rate_oper
	RETURN 0
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[glcfovsp_sp] TO [public]
GO
