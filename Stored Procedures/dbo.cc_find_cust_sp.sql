SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_find_cust_sp] 
	 @doc_ctrl_num varchar(16)

AS

set rowcount 1
select min(customer_code)
from artrx 
where doc_ctrl_num = @doc_ctrl_num
and void_flag = 0
set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[cc_find_cust_sp] TO [public]
GO
