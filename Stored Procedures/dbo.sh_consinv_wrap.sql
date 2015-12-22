SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sh_consinv_wrap] 
	@user varchar(30), 
	@process_ctrl_num varchar(16),
	@group_flag int = 1,  -- jac 04-13-04 0=CUST_CODE 1=SHIPTO, 2=NATNL ACCT   
    @online_call int = 1
AS
BEGIN

DECLARE @err1 int

EXEC dbo.sh_consinv @user , @process_ctrl_num, @err1 OUTPUT,
	@group_flag,  -- jac 04-13-04 0=CUST_CODE 1=SHIPTO, 2=NATNL ACCT 
	@online_call

END
GO
GRANT EXECUTE ON  [dbo].[sh_consinv_wrap] TO [public]
GO
