SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_cust_not_in_wl_sp] 	@user_name	varchar(30) = '',
																				@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db

	DECLARE @company_name varchar(30)
	SELECT @company_name = company_name from arco

	SELECT 	'company' = @company_name, 
		customer_code,
		customer_name,
 		'status' = CASE status_type WHEN 1 THEN 'ACTIVE' WHEN 2 THEN 'INACTIVE' ELSE 'NO NEW BUSINESS' END,
		location_code,
		territory_code,
		salesperson_code,
		added_by_user_name,
		added_by_date

	FROM 	arcust 
	WHERE customer_code NOT IN ( SELECT DISTINCT customer_code FROM ccwrkmem )

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp 
GO
GRANT EXECUTE ON  [dbo].[cc_cust_not_in_wl_sp] TO [public]
GO
