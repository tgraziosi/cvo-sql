SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glgetbal.SPv - e7.2.2 : 1.12
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[glgetbal_sp]
		@account 		varchar(32),
		@period_end 		int,
		@type 			smallint,
		@curbal 		float 	OUTPUT,
 @net float OUTPUT,
 @curbal_oper float OUTPUT,
 @net_oper float OUTPUT
AS
DECLARE 	@year_start 		int



SELECT	@year_start = MAX( period_start_date )
FROM 	glprd
WHERE 	period_start_date <= @period_end
AND 	period_type = 1001

SELECT @net	= SUM( home_net_change *
 (1-ABS(SIGN(@period_end-balance_date)))),
 @curbal = SUM( home_current_balance ),
 @net_oper = SUM( net_change_oper *
 (1-ABS(SIGN(@period_end-balance_date)))),
 @curbal_oper = SUM( current_balance_oper )
FROM glbal
WHERE balance_type = @type
AND account_code = @account
AND balance_date <= @period_end
AND	balance_until >= @period_end

SELECT	@net = ISNULL( @net, 0.0 ),
 @curbal = ISNULL( @curbal, 0.0 ),
 @net_oper = ISNULL( @net_oper, 0.0 ),
 @curbal_oper = ISNULL( @curbal_oper, 0.0 )

RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glgetbal_sp] TO [public]
GO
