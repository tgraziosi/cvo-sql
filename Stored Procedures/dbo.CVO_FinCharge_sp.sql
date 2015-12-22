SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CVO_FinCharge_sp] @where_clause varchar(255)
-- TAG - 1/2/2013 - get the fin charge code from the bill-to customer (arcust)
-- v1.2 = tag - 031814 - dont include with debit memo activity
AS
--
DECLARE @cutoff_date	int,
		@Create_doc		varchar(1),
		@fc_pct			decimal(20,8)

SELECT @fc_pct = (fin_chg_prc/100) FROM CVO..arfinchg WHERE fin_chg_code = 'LATE'

SET NOCOUNT ON

--
-- SELECT OUT OPTIONS
--
SELECT @cutoff_date = convert(int,substring(@where_clause,charindex('=',@where_clause)+1,6))
SELECT @Create_doc = UPPER(substring(@where_clause,charindex('%',@where_clause)+1,1))

--
IF (object_id('tempdb..#tmp_cvo_finchrg') IS NOT NULL) DROP TABLE #tmp_cvo_finchrg

CREATE TABLE #tmp_CVO_FinChrg
(cust_code			varchar(8),
 shipto_code		varchar(8),
 org_name			varchar(40),
 fac_name			varchar(40),
 doc_ctrl_no		varchar(16),
 date_applied		int,
 date_applied_X		varchar(12),
 date_due			int,
 date_due_X			varchar(12),
 open_amount		decimal(20,2),
 xFlag				varchar(1),
 Create_Doc			varchar(1),
 FC_amt				decimal(20,2)
)

CREATE INDEX #temp_idx1 ON #tmp_CVO_FinChrg (cust_code, doc_ctrl_no)

--
-- GATHER DETAIL
--
INSERT INTO #tmp_CVO_FinChrg
-- Invoices
SELECT h.customer_code,h.ship_to_code,c.customer_name, b.address_name, h.doc_ctrl_num,
	h.date_applied, convert(varchar(12),dateadd(dd,h.date_applied-639906,'01/01/1753'),101) as Date_Apply,
	h.date_due, convert(varchar(12),dateadd(dd,a.date_due-639906,'01/01/1753'),101),
	convert(decimal(20,2),h.amt_net - h.amt_paid_to_date) as Open_Amount, ' ', @Create_doc,
	ROUND(convert(decimal(20,2),h.amt_net - h.amt_paid_to_date) * @fc_pct,2) as FC_amt
  FROM armaster b, arcust c, artrxage a	INNER JOIN artrx h ON a.trx_ctrl_num = h.trx_ctrl_num
 WHERE a.trx_type = 2031
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and a.date_due <= @cutoff_date
and (h.doc_ctrl_num not like 'FIN%' AND h.doc_ctrl_num not like 'FC%')
--tag 1/2/13 and b.fin_chg_code > ''
--and b.fin_chg_code <> 'NOFC'
and c.fin_chg_code > ''
and c.fin_chg_code <> 'NOFC'
   -- v1.2 - 031814 debit promos cant be charged fin charges
and not exists (select 1 from cvo_debit_promo_customer_det dd 
            inner join orders_invoice oi on
            dd.order_no = oi.order_no and dd.ext = oi.order_ext
            and oi.trx_ctrl_num = h.trx_ctrl_num)


UNION
-- OA Cash Receipts
select h.customer_code,h.ship_to_code,c.customer_name, b.address_name,h.doc_ctrl_num,
	h.date_applied, convert(varchar(12),dateadd(dd,h.date_applied-639906,'01/01/1753'),101) as Date_Apply,
	h.date_due, convert(varchar(12),getdate(),101) as Date_Due,
	h.amt_on_acct * -1, ' ', @Create_doc, ROUND((h.amt_on_acct * -1) * @fc_pct,2) as FC_amt
  from  armaster b, arcust c, artrxage a	INNER JOIN artrx h ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2111
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and h.amt_on_acct > 0
and b.fin_chg_code > ''
UNION
-- OA Credit Memos
select h.customer_code,h.ship_to_code,c.customer_name, b.address_name,h.doc_ctrl_num,
	h.date_applied, convert(varchar(12),dateadd(dd,h.date_applied-639906,'1/1/1753'),101) as Date_Apply,
	h.date_due, 
	CASE WHEN h.date_due <> 0 THEN convert(varchar(12),dateadd(dd,h.date_due-639906,'1/1/1753'),101)
							  ELSE convert(varchar(12),dateadd(dd,h.date_applied-639906,'1/1/1753'),101) END as Due_Date,
	ROUND((h.amt_on_acct * -1),2), ' ', @Create_doc, ROUND((h.amt_on_acct * -1) * @fc_pct,2) as FC_amt
 from  armaster b, arcust c, artrxage a	INNER JOIN artrx h ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2161
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and ROUND(h.amt_on_acct,2) > 0
--tag 1/2/13 and b.fin_chg_code > ''
--and b.fin_chg_code <> 'NOFC'
and c.fin_chg_code > ''
and c.fin_chg_code <> 'NOFC'
-- v1.2 - 031814 debit promos cant be charged fin charges
and not exists (select 1 from cvo_debit_promo_customer_det dd 
            where dd.trx_ctrl_num = h.trx_ctrl_num)          
order by h.customer_code, h.ship_to_code


--
CREATE TABLE #tmp_CVO_FinChrg_Open
(cust_code			varchar(8),
 open_amount		decimal(20,2)
)
--
-- SUMMARIZE TOTAL OPEN BY CUSTOMER/SHIP TO
--
INSERT INTO #tmp_CVO_FinChrg_Open
select cust_code, sum(open_amount)
  from #tmp_CVO_FinChrg
group by cust_code
order by cust_code
--
DELETE FROM #tmp_CVO_FinChrg_Open WHERE open_amount <= 0
DELETE FROM #tmp_CVO_FinChrg WHERE cust_code NOT IN (select cust_code from #tmp_CVO_FinChrg_Open)
DELETE FROM #tmp_CVO_FinChrg WHERE FC_amt = 0.00
--
--

IF @Create_doc = 'Y'

	BEGIN
--
	SET ROWCOUNT 0

	CREATE TABLE #tmp_CVO_FinChrg_Data
	(row_id				int identity(1,1),
	 cust_code			varchar(8),
	 open_amount		decimal(20,2),
	 apply_date			int
	)

	INSERT INTO #tmp_CVO_FinChrg_Data
		select cust_code, sum(open_amount), @cutoff_date
		  from #tmp_CVO_FinChrg
		group by cust_code
		order by cust_code

	declare @next_tcn varchar(16), @company varchar(8), @comp_id smallint, @date int, @amt dec(10,2)

	select @company = company_code from glcomp_vw
	select @comp_id = company_id from glcomp_vw
	select @date = 722815 + datediff(dd,'1/1/80',getdate())

	declare @cust_code	varchar(8),
		@ship_to	varchar(8),
		@doc_Ctrl	varchar(16),
		@ord_Ctrl	varchar(16),
		@trx_type	int,
		@terms_code	varchar(10),
		@tax_code	varchar(8),
		@tax_pct	float,
		@tax_amt	float,
		@date_enter	varchar(8),
		@date_apply	varchar(8),
		@date_due	int,
		@iDate_apply	int,
		@amt_gross	float,
		@amt_frt	float,
		@amt_tax	float,
		@amt_disc	float,
		@amt_net	float,
		@amt_due	float,
		@ts_code	varchar(2),
		@qty_2031	float,
		@qty_2032	float,
		@xDate_enter	smalldatetime,
		@xDate_apply	smalldatetime,
		@rowid		bigint,
		@batchid	varchar(16),
		@next_doc	varchar(16),
		@days_due	int,
		@numit int

	DECLARE ap01 CURSOR FOR 
		Select row_id from #tmp_CVO_FinChrg_Data
		Order By row_id

	OPEN ap01

	FETCH NEXT from ap01 INTO @rowid

	while (@@fetch_status=0)

	begin

		Select  @cust_code = cust_code,
				@ship_to = ' ',
				@trx_type = 2031,	
				@xDate_enter = getdate(),
				@iDate_apply = apply_date,
				@amt_due = ROUND(open_amount * @fc_pct,2)
		  from #tmp_CVO_FinChrg_Data
		 where row_id = @rowid

		select @terms_code = terms_code
		  from arcust
		 where customer_code = @cust_code

		EXEC dbo.CVO_CalcDueDate_sp @cust_code, @cutoff_date, @date_due OUTPUT, @terms_code

		select @tax_pct = 0.00
		select @tax_amt = 0.00

		select @tax_pct = sum(amt_tax/100)
		  from artaxdet d, artxtype t
		 where d.tax_type_code = t.tax_type_code
		   and d.tax_code = @tax_code

		select @tax_amt = ROUND(@amt_due * @tax_pct,2)


	IF @amt_due = 0 GOTO Get_Next_Rec

		BEGIN TRANSACTION

		exec arnewnum_sp	@trx_type,				-- @trx_type 		smallint, 
					@next_tcn OUTPUT			-- @next_tcn varchar(16) OUTPUT

		COMMIT TRANSACTION

		BEGIN TRANSACTION
		exec ARGetNextControl_SP	2040,
									@next_doc OUTPUT,
									@numit OUTPUT
		COMMIT TRANSACTION


		If @trx_type = 2031
		begin
		   select @qty_2031 = 1
		   select @qty_2032 = 0
		end

		If @trx_type = 2032
		begin
		   select @qty_2031 = 0
		   select @qty_2032 = 1
		end

		select @xDate_enter = @date_enter
		select @xDate_apply = @date_apply

		BEGIN TRANSACTION
		
			insert into arinpchg_all						-- select * from arinpchg_all
			select 
				NULL,						-- timestamp,
				@next_tcn,					-- trx_ctrl_num,
				@next_doc,
				'Finance Charge',				-- doc_desc,
				' ',
				0,
				' ',					-- Order Ctrl
				'',						-- batch_code,
				@trx_type,					-- trx_type
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_entered,
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_apply)+ 639906,			-- date_applied,
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_doc,
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_shipped,
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_required,
				@date_due,				--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_due,
				@date_due,				--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,			-- date_aging,
				armaster.customer_code,	
				' ',
				armaster.salesperson_code,
				armaster.territory_code,
				'',						-- comment_code,
				' ',					-- fob_code,
				' ',			
				armaster.terms_code,				-- terms_code
				' ',
				' ',								-- price_code,
				' ',
				armaster.posting_code,				-- Posting Code
				recurring_code = CASE @trx_type WHEN 2031 THEN 0
								ELSE 1
				END,						-- recurring_code,
				' ',
				'NOTAX',				-- tax_code,
				' ',						-- Customer PO
				0,
				convert (float,@amt_due),			-- amt_gross,
				0,						-- amt_freight,
				0,						-- amt_tax,
				0,						-- amt_tax_include,
				0,						-- amt_discount,
				convert (float,@amt_due + 0),			-- amt_net,
				0,						-- amt_paid,
				convert (float,@amt_due + 0),			-- amt_due,
				0,						-- amt_cost,
				0,						-- amt_profit,
				0,						
				1,						-- Printed
				0,						-- Posted
				0,						-- Hold Flag
				' ',						-- Hold Desc
				1,
				IsNull(armaster.addr1,' '),
				IsNull(armaster.addr2,' '),
				IsNull(armaster.addr3,' '),
				IsNull(armaster.addr4,' '),
				IsNull(armaster.addr5,' '),
				IsNull(armaster.addr6,' '),
				' ',
				' ',
				' ',
				' ',
				' ',
				' ',
				' ',
				' ',
				0,				
				0,				
				0,				
				'001',
				NULL,
				NULL,
				NULL,
				0,
				0,
				'USD',						-- nat_cur_code,
				'BUY',						-- rate_type_home,
				'BUY',						-- rate_type_oper,
				1,						-- rate_home,
				1,						-- rate_oper,
				0,
				NULL,
				NULL,
				0,
				'CVO',						--org_id
				IsNull(armaster.country_code,' '),
				IsNull(armaster.city,' '),
				IsNull(armaster.state,' '),
				IsNull(armaster.postal_code,' '),
				' ',
				' ',
				' ',
				' '
			from 	arcust armaster
			where	@cust_code = armaster.customer_code

	--		
	--		
			insert into arinpcdt
			select 
				NULL,							-- timestamp,
				@next_tcn,						-- trx_ctrl_num,
				@next_doc,
				1,							-- sequence_id,
				@trx_type,						-- trx_type
				' ',							-- location_code,
				' ',							-- item_code,
				0,							-- bulk_flag,
				@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,		-- date_entered,
				'MONTHLY FINANCE CHARGE',					-- line_desc,
				@qty_2031,						-- qty_ordered,
				@qty_2031,						-- qty_shipped,
				' ',
				convert (float,@amt_due),				-- unit_price,
				0,
				0,
				0,							-- serial_id,
				'NOTAX',					-- tax_code
				'4910000000000',					-- gl_exp_acct,
				0,
				0,							-- amt_discount,
				0,
				'',							-- rma_num,
				' ',
				@qty_2032,						-- qty_returned,
				0,							-- qty_prev_returned,
				' ',	
				1,				
				0,				
				0,	
				convert (float,@amt_due),				-- amt_extended,
				0,							-- calc_tax,
				'',							-- reference_code,
	      		'',							-- new_reference_code
				' ',
				'CVO'							--org_id
			from 	arcust armaster
			where	@cust_code = armaster.customer_code
	--		
	--		
			If @trx_type = '2031'
			begin
				insert into arinpage
				select 
					NULL,							-- timestamp
					@next_tcn,						-- trx_ctrl_num
					1,							-- sequence_id
					@next_doc,
					' ',
					0,
					@trx_type,						-- trx_type
					@cutoff_date,			--datediff(dd, '1/1/1753',@xdate_apply)+ 639906,		-- date_applied
					@date_due,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,		-- date_due
					@date_due,			--datediff(dd, '1/1/1753',@xdate_enter)+ 639906,		-- date_aging
					@cust_code,
					armaster.salesperson_code,
					armaster.territory_code,
					armaster.price_code,
					@amt_due + 0
				from 	arcust armaster
				where	@cust_code = armaster.customer_code
			end
	--		
	--		
			insert into arinptax
			select 
				NULL,							-- timestamp
				@next_tcn,						-- trx_ctrl_num
				@trx_type,						-- trx_type
				1,							-- sequence_id
				'NOTAX',					-- tax_type_code
				@amt_due,						-- amt_taxable
				convert (float,@amt_due),				-- amt_gross
				0,							-- amt_tax
				0							-- amt_final_tax
			from 	arcust armaster
			where	@cust_code = armaster.customer_code
		
		--End

		COMMIT TRANSACTION

	Get_Next_Rec:

		FETCH NEXT from ap01 INTO @rowid

	end 

	close ap01 
	deallocate ap01

END


--
-- RETURN RECORDS TO EXPLORER
--
SELECT * FROM #tmp_CVO_FinChrg ORDER BY cust_code, date_due


--

GO
GRANT EXECUTE ON  [dbo].[CVO_FinCharge_sp] TO [public]
GO
