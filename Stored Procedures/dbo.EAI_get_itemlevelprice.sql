SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/


CREATE PROCEDURE [dbo].[EAI_get_itemlevelprice] 
     @part_no varchar(30), @qty decimal(20,8)  AS
BEGIN
    declare @price_level char(1) 
    
    declare @base_price_qty_breaks varchar(3)
    declare @qty_1 decimal(20,8), @qty_2 decimal(20,8)
    declare @qty_3 decimal(20,8), @qty_4 decimal(20,8)
    declare @qty_5 decimal(20,8)
    
    select @qty_1=0, @qty_2=0 , @qty_3=0, @qty_4=0 , @qty_5=0
 
    -- Method for determining base price (list price) Either use qty breaks ('YES') or use qty 1 ('NO')
    select @base_price_qty_breaks = (select value_str from config where flag = 'OE_SPEC_PRICING')

    if (SELECT count(*) from dbo.part_price where part_no = @part_no ) <> 0
	    begin -- Get the qty breaks for the transaction 
		SELECT	@qty_1 = qty_a,
			@qty_2 = qty_b,
			@qty_3 = qty_c,
			@qty_4 = qty_d,
			@qty_5 = qty_e
		FROM dbo.part_price 
		WHERE part_no = @part_no 
	    end
    


    if (@base_price_qty_breaks = 'YES') 
      begin
       select  @price_level = case
			 when  (@qty_5 > 0 and @qty >= @qty_5) then '5'
			 when  (@qty_4 > 0 and @qty >= @qty_4) then '4'
			 when  (@qty_3 > 0 and @qty >= @qty_3) then '3'
			 when  (@qty_2 > 0 and @qty >= @qty_2) then '2'
			 else '1' end  
      end	 		 
    else
	   select @price_level = '1'
    

    select @price_level 'plevel'

END
GO
GRANT EXECUTE ON  [dbo].[EAI_get_itemlevelprice] TO [public]
GO
