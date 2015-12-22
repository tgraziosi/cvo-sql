SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcfsprd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcfsprd_sp]
AS

DECLARE @start_date int, @end_date int, @min_date_applied int

SELECT 	@min_date_applied = min(date_applied)
FROM 	gltrx
WHERE 	posted_flag = 1

SELECT	@start_date = period_start_date, 
 	@end_date = period_end_date
FROM 	glprd
WHERE 	@min_date_applied BETWEEN period_start_date AND period_end_date

SELECT isnull(@start_date,0), isnull(@end_date,0)
GO
GRANT EXECUTE ON  [dbo].[glcfsprd_sp] TO [public]
GO
