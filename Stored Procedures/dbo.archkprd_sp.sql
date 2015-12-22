SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\archkprd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[archkprd_sp] @period_start_date int 
AS 
BEGIN 
	DECLARE @return_code int 
	
	IF EXISTS ( SELECT date_from 
					FROM arsumcus 
					WHERE date_from = @period_start_date ) 
	BEGIN 
		SELECT @return_code = 1 
		RETURN @return_code 
	END 

	IF EXISTS ( SELECT date_from 
					FROM arsumprc 
					WHERE date_from = @period_start_date ) 
	BEGIN 
		SELECT @return_code = 1 
 		RETURN @return_code 
	END 

	IF EXISTS ( SELECT date_from 
					FROM arsumshp 
					WHERE date_from = @period_start_date ) 
	BEGIN 
		SELECT @return_code = 1 
		RETURN @return_code 
	END 

	IF EXISTS ( SELECT date_from 
 					FROM arsumslp 
					WHERE date_from = @period_start_date ) 
	BEGIN 
		SELECT @return_code = 1 
 		RETURN @return_code 
	END 

	IF EXISTS ( SELECT date_from 
					FROM arsumter 
					WHERE date_from = @period_start_date ) 
 	BEGIN 
		SELECT @return_code = 1 
		RETURN @return_code 
	END 

	IF EXISTS ( SELECT date_from 
 					FROM arivcomm 
					WHERE date_from = @period_start_date ) 
	BEGIN 
		SELECT @return_code = 1 
 		RETURN @return_code 
	END 
END 



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[archkprd_sp] TO [public]
GO
