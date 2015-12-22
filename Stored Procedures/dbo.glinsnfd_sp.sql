SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glinsnfd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glinsnfd_sp] 

	@seq_id int, 		@bud_code varchar(16),
	@pd_end_date int, 	@acct_code varchar(32), 
	@uom varchar(16),	@qty float, 
	@ytd_qty float,		@seg1_code varchar(32),
	@seg2_code varchar(32),	@seg3_code varchar(32),
	@seg4_code varchar(32)
AS
BEGIN

	INSERT #glnofinimp (
		sequence_id, 		nonfin_budget_code, 	
		period_end_date, 	account_code, 		
		unit_of_measure, 	quantity, 	 	
		ytd_quantity, 		seg1_code, 	 	
		seg2_code, 		seg3_code, 	 	
		seg4_code,		changed_flag ) 
	VALUES (@seq_id,		@bud_code, 
		@pd_end_date, 		@acct_code, 
		@uom, 	 		@qty, 
		@ytd_qty, 		@seg1_code,
		@seg2_code, 		@seg3_code,
		@seg4_code,		0 )
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glinsnfd_sp] TO [public]
GO
