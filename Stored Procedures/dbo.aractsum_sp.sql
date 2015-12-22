SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\aractsum.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROC [dbo].[aractsum_sp]		@aractcus	smallint,
					@aractshp	smallint,
					@aractprc	smallint,
					@aractslp	smallint,
					@aractter	smallint,
					@arsumcus	smallint,
					@arsumshp	smallint,
					@arsumprc	smallint,
					@arsumslp	smallint,
					@arsumter	smallint
 	 
AS


	IF( @aractcus = 1 )
 	BEGIN
 		EXEC ARUPDateCustActivity_SP 
	END

	IF( @aractprc = 1 )
 	BEGIN
	 	EXEC ARUPDatePriceActivity_SP 
 	END
 	
	IF( @aractshp = 1 )
 	BEGIN
	 	EXEC ARUPDateShipToActivity_SP 
 	END
 	
	IF( @aractslp = 1 )
 	BEGIN
	 	EXEC ARUPDateSalesActivity_SP 
 	END
 	
	IF( @aractter = 1 )
 	BEGIN
	 	EXEC ARUPDateTerrActivity_SP 
 	END
 	
	IF( @arsumcus = 1 )
 	BEGIN
	 	EXEC ARUPDateCustSummary_SP 
 	END
 	
	IF( @arsumprc = 1 )
 	BEGIN
	 	EXEC ARUPDatePriceSummary_SP 
 	END
 	
	IF( @arsumshp = 1 )
 	BEGIN
	 	EXEC ARUPDateShipToSummary_SP 
 	END
 	
	IF( @arsumslp = 1 )
 	BEGIN
	 	EXEC ARUPDateSalesSummary_SP 
 	END
 	
	IF( @arsumter = 1 )
 	BEGIN
	 	EXEC ARUPDateTerrSummary_SP 
	END











/**/                                              
GO
GRANT EXECUTE ON  [dbo].[aractsum_sp] TO [public]
GO
