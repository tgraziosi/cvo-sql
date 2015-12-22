SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CVO_POAMT]
AS
declare @customer_code varchar(15)
declare @suma float

DECLARE customer_cursor CURSOR FOR                              
select distinct po_no from purchase                              
                              
OPEN customer_cursor;                              
                              
                              
                              
FETCH NEXT FROM customer_cursor                              
INTO @customer_code;                              
                              
WHILE @@FETCH_STATUS = 0                              
BEGIN                              


set @suma=(select SUM(unit_cost*qty_ordered) from pur_list where po_no=@customer_code)
update purchase set total_amt_order=@suma where po_no=@customer_code


  FETCH NEXT FROM customer_cursor                              
   INTO @customer_code                              
END                              
                              
CLOSE customer_cursor;                              
DEALLOCATE customer_cursor; 




GO
GRANT EXECUTE ON  [dbo].[CVO_POAMT] TO [public]
GO
