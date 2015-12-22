SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\qtybreak.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROCEDURE [dbo].[qtybreak_sp] 
	@item_code varchar(30),
	@location_code varchar(9),
	@unit_code varchar(8),
	@customer_code varchar(30),
	@price_code varchar(30),
	@price_date int, 
	@cur_rate float
	
AS


RETURN 0
 
GO
GRANT EXECUTE ON  [dbo].[qtybreak_sp] TO [public]
GO
