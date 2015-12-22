SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[adm_cost_adjust] @part varchar(30), @loc varchar(10),@qty_chg decimal(20,8),
	@qty decimal(20,8),@tran_code char(1), @tran_no int, @tran_ext int, @tran_line int,
	@account varchar(10), @tran_date datetime, @tran_age datetime, @unitcost decimal(20,8),
	@direct decimal(20,8), @overhead decimal(20,8),	@labor decimal(20,8), @utility decimal(20,8),
	@stkacct varchar(10), @adj_typ varchar(10), @alloc_no int, @a_tran_id int OUT

AS
BEGIN
-- NOTE:  THIS STORED PROCEDURE IS NO LONGER USED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--        THIS STORED PROCEDURE IS WAS ONLY CALLED FROM LC_ALLOC_LIST INSERT TRIGGER!!!!!

-- This is a new stored procedure to adjust the cost layers for an item.  Instead of doing a
-- delete and then insert to modify a cost layer, which makes it difficult to adjust when dealing with
-- slight variations in cost, this one adjusts the costs in place.  It puts a cost layer with an account of
-- ADJUST.  This is read by the inv_costing insert trigger to adjust the average cost.  Then the original
-- cost layer quantities are updated by this routine and the adjust cost layer is deleted.
-- MLS 7/8/99 SCR 70 20153 

return 1
































 
END

GO
GRANT EXECUTE ON  [dbo].[adm_cost_adjust] TO [public]
GO
