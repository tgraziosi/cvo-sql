SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 05/03/2012 - If past due then check the CC aging before failing    
-- v1.1 CB 07/10/2012 - Return past due before credit limit (only used by adm)
-- v1.2 CB 17/12/2012 - Need to deal with past due for national accounts
-- v1.3 CB 17/01/2013 - Fix issue of a parent being picked up when one doesn not exist
-- v1.4 CB 21/01/2013 - If client is amt_over then it is being overwritten by parent
-- v1.5 CB 28/02/2013 - Re-Write to use C & C data
-- v1.6 CB 08/05/2013 - Performance
-- v1.7 CB 14/05/2013 - Fix calculation
-- v1.8 CB 28/05/2013 - Issue #1181 - When checking the aging brackets use the value as a starting point rather than check on the bracket specified
-- v1.9 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.0 CB 02/08/2013 - Fix when running by customer with no parent
-- v2.1 CB 11/11/2013 - Fix issue when check non bg parents
-- v2.2 CB 15/11/2013 - Fix issue when check non bg parents
-- v2.3 CB 18/11/2013 - Correct issue when check by bg or parent
-- v2.4 CB 25/03/2014 - Issue #1388 - Credit checking if RX order do not include finance charges or charge backs in over due calc
-- v2.5 CB 26/03/2014 - Issue #1388 - Aging check and allowance
-- v2.6 CB 04/04/2014 - Issue #1388 - Aging check and allowance
/*
DECLARE @amt_over float, @date_over int, @credit_failed varchar(8), @aging_failed varchar(8), @credit_check_rel_code varchar(8), @ret int
EXEC @ret = archklmt_sp '035166',0,1000.00,734927,18000,@amt_over OUTPUT, @date_over OUTPUT, @credit_failed OUTPUT, @aging_failed OUTPUT, @credit_check_rel_code OUTPUT
SELECT @amt_over, @date_over, @credit_failed, @aging_failed, @credit_check_rel_code
SELECT @ret
 */

CREATE PROC [dbo].[archklmt_sp]	@customer_code			varchar(8),  
						@amount_home			float,  
						@amount_oper			float,  
						@date_entered			int,  
						@module					smallint,  
						@amt_over				float    OUTPUT,   
						@date_over				int    OUTPUT,  
						@credit_failed			varchar(8) OUTPUT,   
						@aging_failed			varchar(8) OUTPUT,   
						@credit_check_rel_code	varchar(8) OUTPUT
AS  
	-- v1.5 Start

	-- Declarations
	DECLARE	@credit_limit		float,   
			@aging_bracket		int,
			@parent				varchar(10),
			@rel_code			varchar(10),
			@check_credit_limit smallint,  
			@check_aging_limit  smallint,
			@open_orders		decimal(28,2),
			@open_orders2		decimal(28,2),
			@open_ar			float,
			@balance			float,
			@bracket_balance	float,
			@aging_check		int, -- v2.5
			@aging_allowance	float, -- v2.5
			@temp				float -- v2.6

	-- Working tables
	CREATE TABLE #customers( customer_code varchar(8) )  
  
	CREATE TABLE #temp(
		customer_code		varchar(8),  
		doc_ctrl_num		varchar(16) NULL,  
		date_doc			varchar(20)   NULL,  
		trx_type			int   NULL,  
		amt_net				float   NULL,  
		amt_paid_to_date	float   NULL,  
		balance				float   NULL,  
		on_acct_flag		varchar(5)  NULL,  
		nat_cur_code		varchar(8)  NULL,  
		apply_to_num		varchar(16)  NULL,  
		trx_type_code		varchar(8)  NULL,  
		trx_ctrl_num		varchar(16)  NULL,  
		status_code			varchar(5)  NULL,  
		status_date			varchar(20)   NULL,  
		cust_po_num			varchar(20)  NULL,  
		age_bucket			smallint NULL,  
		date_due			varchar(20)  NULL,  
		order_ctrl_num		varchar(16) NULL,
		comment_count		int,
		[rowCount]			int)

	CREATE TABLE #brackets (
		amount		float,
		on_acct		float,
		b1			float,
		b2			float,
		b3			float,
		b4			float,
		b5			float,
		b6			float,
		home_curr	varchar(8),
		b0			float)


	-- Get the national accounts rel code 
	SELECT	@rel_code = credit_check_rel_code
	FROM	arco (NOLOCK)

	INSERT #customers  
	SELECT @customer_code

	-- v2.3 Start
	-- Get the parent
	SET @parent = ''
	SELECT @parent = dbo.f_cvo_get_buying_group(@customer_code,CONVERT(varchar(10),DATEADD(DAY, @date_entered - 693596, '01/01/1900'),121))

	IF (ISNULL(@parent,'') <> '')-- v2.0 v2.2
	BEGIN
		INSERT	#customers
		SELECT	* FROM dbo.f_cvo_get_buying_group_child_list(@parent,CONVERT(varchar(10),DATEADD(DAY, @date_entered - 693596, '01/01/1900'),121))
		SET @customer_code = @parent
	END

	IF (ISNULL(@parent,'') = '') -- v2.0 v2.2
	BEGIN
		SELECT	@parent = parent
		FROM	artierrl (NOLOCK)
		WHERE	rel_cust = @customer_code
		AND		tier_level > 1
		AND		relation_code = @rel_code

		INSERT	#customers  
		SELECT	child   
		FROM	arnarel (NOLOCK)
		WHERE	parent = @parent
		AND		relation_code = @rel_code

		IF (ISNULL(@parent,'') <> '')
			SET @customer_code = @parent

	END
	-- v2.2 End

	IF (ISNULL(@parent,'') = '')
	BEGIN
		IF EXISTS (SELECT 1 FROM arnarel (NOLOCK) WHERE parent = @customer_code)
		BEGIN
			IF EXISTS (SELECT 1 FROM arcust (NOLOCK) WHERE customer_code = @customer_code AND addr_sort1 = 'Buying Group')
			BEGIN
				INSERT	#customers
				SELECT	* FROM dbo.f_cvo_get_buying_group_child_list(@customer_code,CONVERT(varchar(10),DATEADD(DAY, @date_entered - 693596, '01/01/1900'),121))
			END
			ELSE
			BEGIN
				INSERT	#customers  
				SELECT	child   
				FROM	arnarel (NOLOCK)
				WHERE	parent = @customer_code
				AND		relation_code = @rel_code
			END
		END
	END

	-- v2.3 End

	-- Get the credit checking info
	SELECT	@credit_limit = credit_limit,
			@aging_bracket = aging_limit_bracket,
			@check_credit_limit = check_credit_limit,
			@check_aging_limit = check_aging_limit
	FROM	arcust (NOLOCK)
	WHERE	customer_code = @customer_code

	IF (@check_credit_limit = 0 AND @check_aging_limit = 0)
	BEGIN
		SET	@amt_over = 0
		SET @date_over = 0
		SET @credit_failed = ISNULL(@credit_failed,'')  
		SET @aging_failed = ISNULL(@aging_failed,'')  
		SET	@credit_check_rel_code = ISNULL(@credit_check_rel_code,'')  
		RETURN 0
	END


	-- Get the parent child relationship  
	-- v1.9 Start
--	INSERT	#customers
--	SELECT	* FROM dbo.f_cvo_get_buying_group_child_list(@customer_code,CONVERT(varchar(10),DATEADD(DAY, @date_entered - 693596, '01/01/1900'),121))

--	IF ( SELECT COUNT(*) FROM arnarel (NOLOCK) WHERE parent IN ( SELECT customer_code FROM #customers ) AND relation_code = @rel_code ) > 0  
--		INSERT	#customers  
--		SELECT	child   
--		FROM	arnarel (NOLOCK)
--		WHERE	parent IN ( SELECT customer_code FROM #customers )  
--		AND		relation_code = @rel_code
	-- v1.9 End

	-- Get the open orders
	SELECT	@open_orders = ISNULL(SUM(CASE WHEN type = 'I' THEN (gross_sales + total_tax - total_discount + freight) ELSE ((gross_sales * -1) + (total_tax * -1) - (total_discount * -1) + (freight * -1)) END) , 0)  
	FROM	orders_all (NOLOCK)   
	WHERE	cust_code IN ( SELECT customer_code FROM #customers )  
	AND		status IN ( 'R', 'S', 'T' )   
	AND		UPPER( status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status (NOLOCK) WHERE use_flag = 1 )  -- v1.6
	AND		void = 'N'  
   
	-- v1.7
	SELECT	@open_orders2 = ISNULL(SUM(CASE WHEN type = 'I' THEN (total_amt_order + tot_ord_tax - tot_ord_disc + tot_ord_freight) ELSE ((total_amt_order * -1) + (tot_ord_tax * -1) - (tot_ord_disc * -1) + (tot_ord_freight * -1)) END) , 0 )  
	FROM	orders_all (NOLOCK) -- v1.6
	WHERE	cust_code IN ( SELECT customer_code FROM #customers )  
	AND		status NOT IN ( 'R', 'S', 'T' )   
	AND		UPPER( status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status (NOLOCK) WHERE use_flag = 1 )  -- v1.6
	AND		void = 'N'

	SET		@open_orders2 = @open_orders2 - @amount_home -- v2.4

	-- Use the C & C routines to determine the values to credit check

	--Open AR transactions
	INSERT #temp
	EXEC cc_open_inv_sp @customer_code, 1, 1, 4, 1, 'CVO', 'CVO'

	SELECT @open_ar = SUM(balance) from #temp

	-- Calc customer balance
	SET @balance = ISNULL(@open_ar,0) + ISNULL(@open_orders,0) + ISNULL(@open_orders2,0) + ISNULL(@amount_home,0)

	-- Get aging info
	INSERT #brackets
	EXEC cc_summary_aging_sp @customer_code, '2', 1, 'CVO', 'CVO', @temp OUTPUT, 1 -- v2.6

	-- v2.5 Start
	SELECT	@aging_check = aging_check,
			@aging_allowance = aging_allowance
	FROM	cvo_armaster_all (NOLOCK)
	WHERE	customer_code = @customer_code

	IF (@aging_check = 1)
	BEGIN
		SELECT @bracket_balance = b2 + b3 + b4 + b5 + b6 FROM #brackets	
	END
	IF (@aging_check = 2)
	BEGIN
		SELECT @bracket_balance = b3 + b4 + b5 + b6 FROM #brackets	
	END
	IF (@aging_check = 3)
	BEGIN
		SELECT @bracket_balance = b4 + b5 + b6 FROM #brackets	
	END
	IF (@aging_check = 4)
	BEGIN
		SELECT @bracket_balance = b5 + b6 FROM #brackets	
	END
	IF (@aging_check = 5)
	BEGIN
		SELECT @bracket_balance = b6 FROM #brackets
	END
	SELECT @bracket_balance = @bracket_balance + on_acct FROM #brackets
	-- v2.5 End

	-- v2.5 Start
	-- v1.8 Start
	-- Calc which bracket to check
--	IF (@aging_bracket = 1)
--		SELECT @bracket_balance = b2 + b3 + b4 + b5 + b6 FROM #brackets	
--	IF (@aging_bracket = 2)
--		SELECT @bracket_balance = b3 + b4 + b5 + b6 FROM #brackets
--	IF (@aging_bracket = 3)
--		SELECT @bracket_balance = b4 + b5 + b6 FROM #brackets
--	IF (@aging_bracket = 4)
--		SELECT @bracket_balance = b5 + b6 FROM #brackets
--	IF (@aging_bracket = 5)
--		SELECT @bracket_balance = b6 FROM #brackets
	-- v2.5 End
	-- v1.8 End

	-- Aging Check
-- v2.5	IF (@bracket_balance > 0)
	IF (@bracket_balance > 0 AND @bracket_balance > @aging_allowance) -- v2.5
	BEGIN		
		SET	@amt_over = 0
		SET @date_over = (@aging_bracket * 30)
		SET @credit_failed = ISNULL(@credit_failed,'')  
		SET @aging_failed = @customer_code
		SET	@credit_check_rel_code = @rel_code  
		RETURN -2
	END

	-- Aging Check
-- v2.5	IF (@bracket_balance > 0 AND @check_aging_limit <> 0 )
	IF (@bracket_balance > 0 AND @check_aging_limit <> 0 AND @bracket_balance > @aging_allowance) -- v2.5
	BEGIN		
		SET	@amt_over = 0
		SET @date_over = (@aging_bracket * 30)
		SET @credit_failed = ISNULL(@credit_failed,'')  
		SET @aging_failed = @customer_code
		SET	@credit_check_rel_code = @rel_code  
		RETURN -2
	END

	-- Credit Limit Check
	IF (@balance > @credit_limit AND @check_credit_limit <> 0)
	BEGIN
		SET	@amt_over = (@credit_limit - @balance)
		SET @date_over = 0
		SET @credit_failed = @customer_code
		SET @aging_failed = ISNULL(@credit_failed,'')  
		SET	@credit_check_rel_code = @rel_code  
		RETURN -1
	END

	SET	@amt_over = 0
	SET @date_over = 0
	SET @credit_failed = ISNULL(@credit_failed,'')  
	SET @aging_failed = ISNULL(@aging_failed,'')  
	SET	@credit_check_rel_code = ISNULL(@credit_check_rel_code,'')  
	RETURN 0

/*
  
DECLARE   
 @limit_by_home  smallint,   
 @credit_limit   float,   
 @aging_days   int,  
 @aging_bracket  smallint,   
 @tier_level   smallint,  
 @age1    smallint,   
 @age2    smallint,   
 @age3    smallint,   
 @age4    smallint,   
 @age5    smallint,  
 @total_unposted_cm  float,  
 @check_credit_limit  smallint,  
 @check_aging_limit  smallint,  
 @curr_precision  smallint,  
 @date_aging   int,
 @ret int, -- v1.0
 @parent varchar(10), -- v1.2
 @parent_@aging_bracket smallint, -- v1.2
 @amt_over_parent float -- v1.4
  
  
SELECT @amt_over = 0.0, @date_over = 0   
  
  
SELECT @check_credit_limit = check_credit_limit,  
 @check_aging_limit = check_aging_limit,  
 @credit_limit = credit_limit,  
 @limit_by_home = limit_by_home,  
 @aging_bracket = aging_limit_bracket  
FROM arcust (NOLOCK)  
WHERE customer_code = @customer_code  
  
  
IF (@limit_by_home = 0)  
 SELECT @curr_precision = curr_precision,  
  @amount_home = ROUND(@amount_home,curr_precision)  
 FROM glco (NOLOCK), glcurr_vw  (NOLOCK)
 WHERE home_currency = currency_code  
ELSE  
 SELECT @curr_precision = curr_precision,  
  @amount_oper = ROUND(@amount_oper,curr_precision)  
 FROM glco (NOLOCK), glcurr_vw (NOLOCK)
 WHERE oper_currency = currency_code  
  
  
  
SELECT @aging_days = NULL  
  
SELECT @age1 = age_bracket1,  
 @age2 = age_bracket2,  
 @age3 = age_bracket3,  
 @age4 = age_bracket4,  
 @age5 = age_bracket5  
FROM arco (NOLOCK) 
  
IF @aging_bracket = 1  
 SELECT @aging_days = @age1  
ELSE  
IF @aging_bracket = 2  
 SELECT @aging_days = @age2  
ELSE  
IF @aging_bracket = 3  
 SELECT @aging_days = @age3  
ELSE  
IF @aging_bracket = 4  
 SELECT @aging_days = @age4  
ELSE  
IF @aging_bracket = 5  
 SELECT @aging_days = @age5  
  
  
  
SELECT @credit_check_rel_code = arco.credit_check_rel_code,  
 @tier_level = artierrl.tier_level  
FROM arco (NOLOCK), artierrl (NOLOCK) 
WHERE arco.credit_check_rel_code = artierrl.relation_code  
AND artierrl.rel_cust = @customer_code  
  
   
  
IF @check_credit_limit > 0  
BEGIN  
 IF(@limit_by_home = 0)   
 BEGIN  
    
  SELECT @total_unposted_cm = ISNULL( SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ),@curr_precision)), 0.0 )  
  FROM arinpchg (NOLOCK) 
  WHERE customer_code = @customer_code  
  AND trx_type = 2032  
  AND hold_flag = 0  
   
        SELECT @amt_over = isnull((select amt_balance     -- mls 6/2/03 SCR 31005  
           + amt_inv_unposted   
           + amt_on_order  
     - amt_on_acct   
                  FROM    aractcus (NOLOCK) 
                  WHERE   customer_code = @customer_code),0)  
                  + @amount_home   
    - @total_unposted_cm  
    - @credit_limit  
 END  
 ELSE   
 BEGIN  
    
  SELECT @total_unposted_cm = ISNULL( SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ),@curr_precision)), 0.0 )  
  FROM arinpchg  (NOLOCK)
  WHERE customer_code = @customer_code  
  AND trx_type = 2032  
  AND hold_flag = 0  
   
     
        SELECT @amt_over = isnull((select amt_balance_oper    -- mls 6/2/03 SCR 31005  
           + amt_inv_unp_oper   
           + amt_on_order_oper  
     - amt_on_acct_oper   
                  FROM    aractcus (NOLOCK)  
                  WHERE   customer_code = @customer_code),0)   
            + @amount_oper   
    - @total_unposted_cm  
    - @credit_limit  
 END  
   
 IF ( SIGN(@amt_over) >= 0)  
   
  SELECT @credit_failed = @customer_code  
  
END  
   
  
IF @check_aging_limit > 0  
BEGIN  
   
 SELECT @date_aging = ISNULL(MIN( date_aging ),0)  
 FROM artrxage (NOLOCK) 
 WHERE customer_code = @customer_code  
 AND trx_type <= 2031  
 AND paid_flag = 0  
  
 IF( @date_aging > 0)  
  SELECT @date_over = @date_entered - @aging_days - @date_aging  
 ELSE  
  SELECT @date_over = 0  
   
-- v1.0 Start
 IF ( @date_over > 0 )
 BEGIN  
	SET @ret = 0
	EXEC @ret = cvo_check_customer_balance_sp @customer_code,@aging_days,@aging_bracket
	IF @ret = 0
		SELECT @date_over = 0  
	ELSE
		SELECT @aging_failed = @customer_code  
 END
 ELSE  
   
  SELECT @date_over = 0  
END  

-- IF ( @date_over > 0 )  
--  SELECT @aging_failed = @customer_code  
-- ELSE  
--   
--  SELECT @date_over = 0  
--END  
-- v1.0 End  
  
IF ( LTRIM(@credit_check_rel_code) IS NOT NULL AND LTRIM(@credit_check_rel_code) != ' ' )  
BEGIN  
 EXEC arcrnacc_sp @customer_code,   
    @credit_check_rel_code,   
    @tier_level,   
    @amount_home,  
    @amount_oper,   
    @module,  
    @amt_over_parent  OUTPUT,   
    @credit_failed OUTPUT   
  
-- v1.2 Start - As this is a national account check the parent
	SELECT	@parent = parent 
	FROM	artierrl (NOLOCK)
	WHERE	rel_cust = @customer_code
    AND		tier_level > 1 -- v1.3

	IF (ISNULL(@parent,'') <> '')
	BEGIN

		SELECT	@parent_@aging_bracket = aging_limit_bracket  
		FROM	arcust (NOLOCK)  
		WHERE	customer_code = @parent  		

		SET @ret = 0
		EXEC @ret = cvo_check_customer_balance_sp @parent,@aging_days,@parent_@aging_bracket
		IF @ret = 0
			SELECT @date_over = 0  
		ELSE
			SELECT @date_over = 1
	END
-- v1.2 End
END  
  
  
  
SELECT @credit_failed = ISNULL(@credit_failed,'')  
SELECT @aging_failed = ISNULL(@aging_failed,'')  
SELECT @credit_check_rel_code = ISNULL(@credit_check_rel_code,'')  

IF(@amt_over < 0.0)  
 SELECT @amt_over = 0.0 

-- v1.4 Start
IF @amt_over_parent IS NOT NULL
BEGIN
	SELECT @amt_over_parent = SIGN(@amt_over_parent)
	IF @amt_over = 0
	BEGIN
		IF  SIGN(@amt_over_parent) >= 0
			SET @amt_over = SIGN(@amt_over_parent)
	END
END
-- v1.4 End
  
  
IF ( @module > 0 )   
BEGIN  
-- IF (SIGN(@amt_over) = 1) v1.1
--  RETURN -1  
 IF ( @date_over > 0 )  -- v1.1
  RETURN -2   
 ELSE  
-- IF ( @date_over > 0 )  v1.1
--  RETURN -2   
 IF (SIGN(@amt_over) = 1) -- v1.1
  RETURN -1  

 ELSE  
  RETURN 0  
END  
ELSE  
BEGIN  
 RETURN  
END  
*/
GO
GRANT EXECUTE ON  [dbo].[archklmt_sp] TO [public]
GO
