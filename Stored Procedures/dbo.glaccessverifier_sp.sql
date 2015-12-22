SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create PROC [dbo].[glaccessverifier_sp] ( @account_code_glchart varchar(32) , @account_code_ib varchar(32) )
AS

SELECT COUNT(1), (SELECT COUNT (1) FROM glchart WHERE account_code = @account_code_glchart )  
FROM sm_accounts_access_co_vw 
WHERE account_code = @account_code_ib

GO
GRANT EXECUTE ON  [dbo].[glaccessverifier_sp] TO [public]
GO
