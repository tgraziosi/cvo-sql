SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
  
-- TEST select * from orders where status = 'c'  
-- EXEC CVO_email_credithold_sp 1419853  
-- tag - move email check to later ...  
  
CREATE PROCEDURE [dbo].[CVO_email_credithold_sp] @order_no INT  
AS  
  
BEGIN  

	-- v3.1 CB 07/08/2013 - Issue #1044 - Email Changes   
	-- v3.2 EL 08/20/2013 = (additional format changes)
	-- v3.3 CB 17/10/2013 - Issue #1398 - Credit limit should come from BG if customer is a child
	-- v3.4 CB 15/11/2013 - Fix issue for displaying credit limit for non bg parents
	-- v3.5 CB 18/11/2013 - Fix issue for displaying open orders
	-- v3.6 TG 06/03/2014 - record additional fields in cvo_credithold_sent table
    -- tag 3/2019 - don't do aging buckets for bg customers
  
-- aging info  
  
	DECLARE @cvo_accounting_email	VARCHAR(40),  
			@SUBJECT				VARCHAR(255),  
			@MESSAGE				VARCHAR(8000)  
  
	DECLARE @hold_reason			varchar(10), 
			@order_type				varchar(10), 
			@sales_rep				varchar(10),  
			@territory				varchar(10), 
			@cust_code				varchar(10), 
			@cust_name				varchar(40),  
			@contact_name			varchar(40), 
			@contact_phone			varchar(30), 
			@order_value			decimal(20,2),  
			@cred_limit				decimal(20,2), 
			@open_order				decimal(20,2), 
			@order_nox				varchar(10),  
			@region_id				varchar(10), 
			@cust_type				varchar(40),  
			@bg_code				varchar(10), 
			@bg_name				varchar(40),   --v1.1  
			@order_Frght			decimal(20,2), 
			@order_Tax				decimal(20,2),         --v3.0  
			@order_Disc				decimal(20,2), 
			@order_Net				decimal(20,2), 
			@alloc_date				varchar(10),  --v3.0  
			@CC_Status				varchar(10),                  --v3.0  
			@parent					varchar(10) -- v3.4


	-- v3.1 Start
	DECLARE	@amount				decimal(20,2),
			@on_acct			decimal(20,2),
			@amt_age_bracket1	decimal(20,2),
			@amt_age_bracket2	decimal(20,2),
			@amt_age_bracket3	decimal(20,2),
			@amt_age_bracket4	decimal(20,2),
			@amt_age_bracket5	decimal(20,2),
			@amt_age_bracket6	decimal(20,2),
			@home_currency		varchar(10),
			@amt_age_bracket0	decimal(20,2)
	-- v3.1 End
	
	-- 3.2 cvo changes to email
	declare @charnum varchar(12)
  
	-- v3.0  Do not send a notification if one has already been sent  
	IF EXISTS(SELECT 1 FROM CVO_CreditHold_Sent WHERE order_no = @order_no)  
	BEGIN  
		RETURN  
	END  
	-- v3.0  
  
	-- v3.5 Start
	CREATE TABLE #customers (
		customer_code	varchar(10))
	-- v3.5 End

  
	-- START PROCESS  
	IF (select @@SERVERNAME) = 'CVO-DB-03'  
	BEGIN  
		SELECT @cvo_accounting_email = 'eorders@cvoptical.com'  
	END  
	ELSE  
	BEGIN  
		select @cvo_accounting_email = 'mrodecker@cvoptical.com'  
	END  
       
	SELECT	@order_nox = CONVERT(char(10),order_no),  
			@hold_reason = IsNull(o.hold_reason,' '),  
			@order_type = o.user_category, 
			@sales_rep = IsNull(o.salesperson,' '),  
			@territory = IsNull(o.ship_to_region,' '),  
			@cust_code = o.cust_code,  
			@cust_name = IsNull(a.customer_name,' '),  
			@contact_name = IsNull(a.attention_name,' '), 
			@contact_phone = IsNull(a.attention_phone,' '),  
			@order_value = IsNull(o.total_amt_order,0),  
			@cred_limit = IsNull(a.credit_limit,0),  
			@cust_type = IsNull(UPPER(a.addr_sort1),' '),  
			@order_Frght = IsNull(tot_ord_freight,0), 
			@order_Tax = IsNull(tot_ord_tax,0),     --v3.0  
			@order_Disc = IsNull(tot_ord_disc,0),                --v3.0  
			@order_Net = IsNull(((total_amt_order + (tot_ord_freight + tot_ord_tax)) - tot_ord_disc),0)   --v3.0  
	FROM	orders_all o (NOLOCK)  
	LEFT OUTER JOIN arcust a (NOLOCK) 
	ON		o.cust_code = a.customer_code  
	WHERE	o.order_no = @order_no  
  
	--v2.0 Add Buying Group Name  
	SELECT	@bg_code = IsNull(buying_group,''), 
			@bg_name = IsNull(customer_name,'')  
	FROM	CVO_orders_all (NOLOCK)
	INNER JOIN arcust (NOLOCK) 
	ON		buying_group = customer_code  
	WHERE	order_no = @order_no 
	AND		ext = 0  
--  
	SELECT	@alloc_date = IsNull(convert(varchar(12),allocation_date,101),' ') 
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no 
	AND		ext = 0  
  
	--v3.0 Get C&C Customer Status  
	select	@CC_Status = IsNull(status_code,'') 
	FROM	cc_cust_status_hist (NOLOCK) 
	WHERE	clear_date is NULL 
	AND		customer_code = @cust_code  
  
	SELECT	@open_order = sum(IsNull(((total_amt_order + (tot_ord_freight + tot_ord_tax)) - tot_ord_disc),0)) 
	FROM	orders_all (NOLOCK)  
	WHERE	cust_code = @cust_code 
	AND		order_no <> @order_no 
	AND		status < 'R'  
  
	SELECT @region_id = dbo.calculate_region_fn(@territory)
  
	IF LEN(@contact_phone) = 10  
	BEGIN  
		SELECT @contact_phone = '('+substring(@contact_phone,1,3)+') '+substring(@contact_phone,4,3)+'-'+substring(@contact_phone,7,4)  
	END  
  
	IF @cust_type = 'Key Account'  
	BEGIN  
		SET @SUBJECT = @cust_type+' - CREDIT HOLD NOTIFICATION FOR '+@cust_code+'/'+Substring(@cust_name,1,20)+'/'+@order_nox+' '  
	END  
	ELSE  
	BEGIN  
		SET @SUBJECT = @cust_type+' - REGION '+@region_id+' - CREDIT HOLD NOTIFICATION FOR '+@cust_code+'/'+Substring(@cust_name,1,20)+'/'+@order_nox+' '  
	END  
  
	-- tag  
	IF @@servername <> 'cvo-db-03'  
	BEGIN  
		SET @subject = @@servername+' - '+@subject  
	END  
  
	SET @MESSAGE = ''  
  
	--Rob Martin 1/16/2012 - to correct null values in @open_order and @bg fields  
	SELECT	@order_nox=isnull(@order_nox,''),
			@order_type=isnull(@order_type,''),
			@hold_reason=isnull(@hold_reason,''),  
			@territory = isnull(@territory,''),
			@cust_code=isnull(@cust_code,''),
			@bg_code=isnull(@bg_code,''),  
			@cred_limit=isnull(@cred_limit,0), 
			@order_value=isnull(@order_value,0),
			@open_order = isnull(@open_order,0),  
			@contact_name=isnull(@contact_name,''), 
			@contact_phone = isnull(@contact_phone,''), 
			@CC_Status = isnull(@CC_Status,'') --v3.0  
	--end change by Rob Martin  
  
	-- v3.1 Start
	CREATE TABLE #email_cc (
		amount				float,
		on_acct				float,
		amt_age_bracket1	float,
		amt_age_bracket2	float,
		amt_age_bracket3	float,
		amt_age_bracket4	float,
		amt_age_bracket5	float,
		amt_age_bracket6	float,
		home_currency		varchar(10),
		amt_age_bracket0	float)


	
-- 3.2 if BG get aging for buying group
	-- v3.5 Start
	IF (@cust_type = 'Buying Group')
	BEGIN
		SET @bg_code = @cust_code
	END
	-- v3.5


	if @bg_code <> '' 
	BEGIN
    
		--INSERT	#email_cc
	 --   exec cc_summary_aging_sp @bg_code

		-- v3.3 Start
		SELECT	@cred_limit = IsNull(credit_limit,0)	
		FROM	arcust (NOLOCK)
		WHERE	customer_code = @bg_code
		-- v3.3 End
		-- v3.5 Start

		INSERT	#customers
		SELECT	@bg_code

		INSERT	#customers
		SELECT	* FROM dbo.f_cvo_get_buying_group_child_list(@bg_code,CONVERT(varchar(10),GETDATE(),121))

		SELECT	@open_order = sum(IsNull(((a.total_amt_order + (a.tot_ord_freight + a.tot_ord_tax)) - a.tot_ord_disc),0)) 
		FROM	orders_all a (NOLOCK)  
		JOIN	#customers b
		ON		a.cust_code = b.customer_code
		WHERE	order_no <> @order_no 
		AND		status < 'R'  
		-- v3.5 End
	END
	ELSE
	BEGIN
		-- v3.4 Start
		SET @parent = ''
		SELECT	@parent = parent
		FROM	artierrl (NOLOCK)
		WHERE	rel_cust = @cust_code
		AND		tier_level > 1
		AND		relation_code = 'REPORT'

		IF (@parent = '')
		BEGIN
			SELECT	@parent = parent
			FROM	arnarel (NOLOCK)
			WHERE	child = @cust_code
			AND		relation_code = 'REPORT'
		END

		IF (@parent <> '')
		BEGIN

			INSERT	#customers
			SELECT	@parent

			INSERT	#customers
			SELECT	rel_cust
			FROM	artierrl (NOLOCK)
			WHERE	parent = @parent
			AND		tier_level > 1
			AND		relation_code = 'REPORT'
			
			INSERT	#email_cc
			EXEC cc_summary_aging_sp @parent

			SELECT	@cred_limit = IsNull(credit_limit,0),	
					@bg_name = IsNull(customer_name,'')
			FROM	arcust (NOLOCK)
			WHERE	customer_code = @parent

			SELECT	@open_order = sum(IsNull(((a.total_amt_order + (a.tot_ord_freight + a.tot_ord_tax)) - a.tot_ord_disc),0)) 
			FROM	orders_all a (NOLOCK)  
			JOIN	#customers b
			ON		a.cust_code = b.customer_code
			WHERE	order_no <> @order_no 
			AND		status < 'R'  

		END
		ELSE
		BEGIN
			INSERT	#email_cc
			EXEC cc_summary_aging_sp @cust_code

		END
    end
    
-- check for nulls - TAG - 8/13/2013
	SELECT	@amount = isnull(amount,0),
			@on_acct = isnull(on_acct,0),
			@amt_age_bracket1 = isnull(amt_age_bracket1,0), 
			@amt_age_bracket2 = isnull(amt_age_bracket2,0),
			@amt_age_bracket3 = isnull(amt_age_bracket3,0), 
			@amt_age_bracket4 = isnull(amt_age_bracket4,0), 
			@amt_age_bracket5 = isnull(amt_age_bracket5,0),
			@amt_age_bracket6 = isnull(amt_age_bracket6,0),	
			@home_currency = isnull(home_currency,''),
			@amt_age_bracket0 = isnull(amt_age_bracket0,0)		
	FROM	#email_cc

	DROP TABLE #email_cc
	-- v3.1 End

  
	SELECT @MESSAGE = 'The following order has been placed on Credit Hold <BR><BR>'  
	SELECT @MESSAGE = @MESSAGE + '<B>Order#: ' + @order_nox + '</B><BR>Order Type: ' + @order_type + '<BR>Hold Status: ' + @hold_reason + ' '  
	SELECT @MESSAGE = @MESSAGE + '<BR>Territory: ' + @territory + '<BR>C&C Status: ' + @CC_Status + ' <BR><BR> '  
	SELECT @MESSAGE = @MESSAGE + 'Customer: ' + @cust_code + ' / ' + @cust_name + ' <BR>'  
	-- v3.5 Start
	IF (@bg_code <> '')
	BEGIN
		SELECT @MESSAGE = @MESSAGE + 'Parent  : ' + IsNull(@bg_code,'') + ' / ' + IsNull(@bg_name,'') + ' <BR><BR>'  
	END
	ELSE
	BEGIN
		IF (@parent <> '')
			SELECT @MESSAGE = @MESSAGE + 'Parent  : ' + IsNull(@parent,'') + ' / ' + IsNull(@bg_name,'') + ' <BR><BR>'  
		ELSE
			SELECT @MESSAGE = @MESSAGE + 'Parent  : <BR><BR>'  
	END
	-- v3.5 End
	SELECT @MESSAGE = @MESSAGE + '<B>Credit Limit: ' + convert(char(12),@cred_limit) + '</B><BR><BR>'   --V3.2 Bold
---- v3.1 Start
--	SELECT @MESSAGE = @MESSAGE + '<table border="0"><col width="80"><col width="80"><col width="80"><col width="80"><col width="80"><col width="80"><col width="80"><col width="80">'
--	SELECT @MESSAGE = @MESSAGE + '<tr><td>AR Balance</td><td>Future</td><td>Current</td><td><B>+ 30</B></td><td><B>+ 60</B></td><td><B>+ 90</B></td><td><B>+ 120</B></td><td><B>+ 150</B></td></tr>'
--	SELECT @MESSAGE = @MESSAGE + '<tr><td>' + CAST(@amount as varchar(12)) + '</td><td>' + CAST(@amt_age_bracket0 as varchar(12)) + '</td><td>' + CAST(@amt_age_bracket1 as varchar(12)) + '</td>'
--	SELECT @MESSAGE = @MESSAGE + '<td>' + CAST(@amt_age_bracket2 as varchar(12)) + '</td><td>' + CAST(@amt_age_bracket3 as varchar(12)) + '</td><td>' + CAST(@amt_age_bracket4 as varchar(12)) + '</td>'
--	SELECT @MESSAGE = @MESSAGE + '<td>' + CAST(@amt_age_bracket5 as varchar(12)) + '</td><td>' + CAST(@amt_age_bracket6 as varchar(12)) + '</td></tr></table><BR>'
---- v3.1 End

-- v3.2 Start
    IF @bg_code = ''
    BEGIN
	SELECT @MESSAGE = @MESSAGE + '<table border="0"><col width="80"><col width="80">'
	
	select @charnum = CASE WHEN @amount >= 0.01 THEN CAST(@amount AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amount) AS VARCHAR(10)) + ')'
    END

	SELECT @MESSAGE = @MESSAGE + '<tr><td>AR Balance</td><td bgcolor="#FFFF66">' + CAST(@charnum as varchar(12)) + '</td></tr>'

	select @charnum = CASE WHEN @amt_age_bracket0 >= 0.01 THEN CAST(@amt_age_bracket0 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket0) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>Future</td><td>' + CAST(@charnum as varchar(12)) + '</td></tr>'
	
	select @charnum = CASE WHEN @amt_age_bracket1 >= 0.01 THEN CAST(@amt_age_bracket1 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket1) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>Current</td><td>' + CAST(@charnum as varchar(12)) 
	+ '</td></tr>'
	
	select @charnum = CASE WHEN @amt_age_bracket2 >= 0.01 THEN CAST(@amt_age_bracket2 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket2) AS VARCHAR(10)) + ')'
    END
    
	SELECT @MESSAGE = @MESSAGE + '<tr><td>+ 30</td><td bgcolor="#0080FF">' + CAST(@charnum as varchar(12)) + '</td></tr>'

    select @charnum = CASE WHEN @amt_age_bracket3 >= 0.01 THEN CAST(@amt_age_bracket3 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket3) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>+ 60</td><td bgcolor="#0080FF">' + CAST(@charnum as varchar(12)) + '</td></tr>'

    select @charnum = CASE WHEN @amt_age_bracket4 >= 0.01 THEN CAST(@amt_age_bracket4 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket4) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>+ 90</td><td bgcolor="#0080FF">' + CAST(@charnum as varchar(12)) + '</td></tr>'

    select @charnum = CASE WHEN @amt_age_bracket5 >= 0.01 THEN CAST(@amt_age_bracket5 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket5) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>+ 120</td><td bgcolor="#0080FF">' + CAST(@charnum as varchar(12)) + '</td></tr>'

    select @charnum = CASE WHEN @amt_age_bracket6 >= 0.01 THEN CAST(@amt_age_bracket6 AS VARCHAR(12))
    ELSE '(' + CAST(ABS (@amt_age_bracket6) AS VARCHAR(10)) + ')'
    END
    	
	SELECT @MESSAGE = @MESSAGE + '<tr><td>+ 150</td><td bgcolor="#0080FF">' + CAST(@charnum as varchar(12)) + '</td></tr></table><BR>'
    END
-- v3.2 End

	SELECT @MESSAGE = @MESSAGE + '<B>Order Net Value: ' + convert(char(12),@order_Net) + '</B><BR><BR>'  
	SELECT @MESSAGE = @MESSAGE + 'Open Order Value: ' + convert(char(12),isnull(@open_order,0)) + '<BR><BR>'  -- v3.1
-- v3.1	SELECT @MESSAGE = @MESSAGE + 'Order Gross Value: ' + convert(char(12),@order_value) + '<BR>'  
-- v3.1	SELECT @MESSAGE = @MESSAGE + 'Order Freight Value: ' + convert(char(12),@order_Frght) + '<BR>'  
-- v3.1	SELECT @MESSAGE = @MESSAGE + 'Order Tax Value: ' + convert(char(12),@order_Tax) + '<BR>'  
-- v3.1	SELECT @MESSAGE = @MESSAGE + 'Order Discount Value: ' + convert(char(12),@order_Disc) + '<BR>'  
	SELECT @MESSAGE = @MESSAGE + '<B>Allocate: ' + convert(char(12),IsNull(@alloc_date,' ')) + '</B><BR>'  
-- v3.1	SELECT @MESSAGE = @MESSAGE + 'Open Order Value: ' + convert(char(12),@open_order) + '<BR><BR>'  
  
	SELECT @MESSAGE = @MESSAGE + '<BR><I>Automated e-mail generated from Epicor.  Please do not respond. </I> '  
  
--	insert cvo_email_test select @order_no, @MESSAGE


	EXEC msdb.dbo.sp_send_dbmail	@profile_name = 'WMS_1',  
									@recipients  = @cvo_accounting_email,   
									@subject  = @SUBJECT,   
									@body   = @MESSAGE,  
									@body_format = 'HTML',  
									@importance  = 'HIGH';  
  
  
	IF NOT EXISTS(SELECT 1 FROM CVO_CreditHold_Sent WHERE order_no = @order_no)  
	BEGIN  
		INSERT INTO CVO_CreditHold_Sent SELECT @order_no, 0, getdate()
		-- TAG 060314
		, @hold_reason, @cc_status, @bg_code, @cred_limit, @amount  
	END  
  
END  
  


GO
GRANT EXECUTE ON  [dbo].[CVO_email_credithold_sp] TO [public]
GO
