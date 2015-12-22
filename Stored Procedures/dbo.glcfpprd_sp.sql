SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcfpprd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcfpprd_sp] (
	@as_of_date		int,
	@s_period_start_date	int,
	@s_period_end_date	int
) 


AS DECLARE @p_period_start_date 	int,
	@p_period_end_date 	int,
	@fp_period_end_date 	int,	
	@fp_period_start_date 	int,	
	@pp_period_end_date 	int,	
	@pp_period_start_date 	int	


SELECT	@p_period_end_date = period_end_date
FROM	glprd
WHERE	period_end_date = @s_period_end_date

IF	@@rowcount = 1		
BEGIN
	
	IF	@p_period_end_date > @as_of_date
		SELECT	@p_period_end_date = 0

	SELECT	p_period_end_date = @p_period_end_date
	RETURN
END


SELECT	@fp_period_end_date = MIN ( period_end_date )
FROM	glprd
WHERE	period_end_date > @s_period_end_date

SELECT	@fp_period_start_date = period_start_date
FROM	glprd
WHERE	period_end_date = @fp_period_end_date


SELECT	@pp_period_end_date = MAX ( period_end_date )
FROM	glprd
WHERE	period_end_date < @s_period_end_date

SELECT	@pp_period_start_date = period_start_date
FROM	glprd
WHERE	period_end_date = @pp_period_end_date


IF	@pp_period_end_date - @s_period_start_date > 
	 ( @s_period_end_date - @fp_period_start_date )
	SELECT	@p_period_end_date = @pp_period_end_date
ELSE	
	SELECT	@p_period_end_date = @fp_period_end_date


IF	@p_period_end_date > @as_of_date
	SELECT	@p_period_end_date = 0

SELECT	p_period_end_date = isnull ( @p_period_end_date, 0 )

RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcfpprd_sp] TO [public]
GO
