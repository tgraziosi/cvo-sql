SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_cost_check] @part varchar(30), @loc varchar(10), @qty decimal(20,8),
	@tran_code char(1), @tran_no int, @tran_ext int, @tran_line int, @account varchar(10),
@layer_qty decimal(20,8) OUT
 AS

BEGIN

--Return QTY found in cost layer for specific tranasaction!
-- Do a no lock??I don't think so but need to check on it.


select @layer_qty = isnull((select sum(balance)
     FROM inv_costing
     WHERE part_no  = @part and
           location = @loc and
	   account  = @account and 
           tran_no  = @tran_no and 
           tran_ext = @tran_ext and
           tran_line= @tran_line and 
           tran_code= @tran_code),0)

END
GO
GRANT EXECUTE ON  [dbo].[adm_cost_check] TO [public]
GO
