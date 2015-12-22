SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                













CREATE PROCEDURE [dbo].[glexchange_rates_sp] 
					
	
AS
BEGIN
	


	UPDATE #exchange_rates
	SET to_cur = home_currency
	FROM glco
	WHERE home = 1
	
	UPDATE #exchange_rates
	SET rate = buy_rate
	FROM CVO_Control..mccurtdt mc
	WHERE #exchange_rates.from_cur = mc.from_currency
	AND #exchange_rates.to_cur = mc.to_currency
	AND #exchange_rates.rate_type = mc.rate_type
	AND #exchange_rates.home = 1
	AND #exchange_rates.apply_date BETWEEN mc.convert_date AND mc.convert_date + valid_for_days -1
		  



	UPDATE #exchange_rates
	SET to_cur = oper_currency
	FROM glco
	WHERE home = 0

	UPDATE #exchange_rates
	SET rate = buy_rate
	FROM CVO_Control..mccurtdt mc
	WHERE #exchange_rates.from_cur = mc.from_currency
	AND #exchange_rates.to_cur = mc.to_currency
	AND #exchange_rates.rate_type = mc.rate_type
	AND #exchange_rates.home = 0
	AND #exchange_rates.apply_date BETWEEN mc.convert_date AND mc.convert_date + valid_for_days -1
	
	


	UPDATE #exchange_rates
	SET rate = 1.0
	WHERE from_cur = to_cur

		
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glexchange_rates_sp] TO [public]
GO
