SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glccalwt.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glccalwt_sp]
	@period_begin		int,		
	@period_end		int,		
	@parent_home_cur	char(30),	
	@subsidiary_home_cur	char(30),	
	@rate_type char(8) 
AS


DECLARE @days_in_period int, @counter int, @avg_rate float

CREATE TABLE #rates ( rate_date int	NOT NULL, rate float NOT NULL )

CREATE TABLE #avg_rate ( rate float NOT NULL )


INSERT	#rates
SELECT	convert_date, buy_rate
FROM	 glcurtdt_vw
WHERE	 convert_date BETWEEN @period_begin AND @period_end
AND	 from_currency = @subsidiary_home_cur
AND	 to_currency = @parent_home_cur
AND rate_type = @rate_type


IF NOT EXISTS 
( SELECT * 
		FROM #rates 
		WHERE rate_date = @period_begin )
 INSERT	#rates
	 SELECT	@period_begin, buy_rate
 FROM	 glcurtdt_vw
 WHERE	 convert_date = ( 	
		 SELECT	MAX ( convert_date ) 
		 FROM	glcurtdt_vw
		 WHERE	convert_date < @period_begin
		 AND	from_currency = @subsidiary_home_cur
		 AND	to_currency = @parent_home_cur 
		 AND rate_type = @rate_type )
 AND	from_currency = @subsidiary_home_cur
 AND	to_currency = @parent_home_cur
 AND rate_type = @rate_type


IF NOT EXISTS 
(	SELECT	* 
		FROM 	#rates 
		WHERE	rate_date = @period_begin )
 INSERT	#rates
 SELECT	@period_begin, buy_rate
 FROM	glcurtdt_vw
 WHERE	convert_date = (
		 SELECT	min(convert_date) 
		 FROM	glcurtdt_vw
		 WHERE	convert_date BETWEEN @period_begin AND @period_end
		 AND	from_currency = @subsidiary_home_cur
		 AND	to_currency = @parent_home_cur 
		 AND	rate_type = @rate_type )
 AND	from_currency = @subsidiary_home_cur
 AND	to_currency = @parent_home_cur
 AND rate_type = @rate_type


IF (SELECT COUNT(rate) FROM #rates) = 0
 INSERT #rates VALUES (@period_begin, 1.0)




SELECT	@days_in_period = @period_end - @period_begin,
	@counter = 0

WHILE	@counter <= @days_in_period
BEGIN
	 INSERT	#avg_rate ( rate )
	 SELECT	rate
	 FROM	#rates
	 WHERE	rate_date = (
		 SELECT	MAX ( rate_date )
		 FROM	#rates
		 WHERE	rate_date <= @counter + @period_begin )

	SELECT	@counter = @counter + 1
END


SELECT	@avg_rate = avg(rate)
FROM	#avg_rate


DROP TABLE #rates
DROP TABLE #avg_rate


SELECT @avg_rate


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glccalwt_sp] TO [public]
GO
