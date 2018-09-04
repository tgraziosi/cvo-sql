SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/**************************************************************************************  
  
      Created 2011 and Protected as Unpublished Work         
     Under the U.S. Copyright Act of 1976              
   Copyright (c) 2011 Epicor Software Corporation, 2011      
      All Rights Reserved        
                    
CREATED BY:    Bruce Bishop  
CREATED ON:   20111129  
PURPOSE:    Generate Buying Group Export Files  
LAST UPDATE:   20120113  
  
  
EXEC CVO_buying_group_export_sp  'INVOICE_DATE BETWEEN ''01/01/2018'' AND ''05/31/2018'''
  
**************************************************************************************/  
  
CREATE PROCEDURE [dbo].[CVO_buying_group_export_sp] (@WHERECLAUSE VARCHAR(1024))  
-- tag 092612 - handle invoice numbers more than 12 characters long  
-- v1.1 CT 13/02/13 - Display Credit Return Fee amount in field #19
-- v1.2 CT 21/03/13 - Logic change for Credit Return Fees
-- v1.3 CT 16/03/13 - When applying credit fee, subtract from line's total and tot_due values
-- tag 053013 - various updates, exclude 100% discount items
-- v1.4 - tg - 031814 - updates for debit promo activity
-- v1.5 CB 31/05/2018 - Changed to use new data extraction sp
-- v1.6 CB 12/06/2018 - Deal with rounding issue on installment invoices
-- v1.7 CB 27/06/2018 - Fix rounding issues
-- v1.8 CB 27/07/2018 - Addition to v1.7
-- v1.9 CB 27/07/2018 - Addition to v1.8
-- v2.0 CB 27/07/2018 - Addition to v1.9
AS  
BEGIN

	DECLARE	@SQL  VARCHAR(1000),  
			@FILENAME  VARCHAR(200),  
			@BCPCOMMAND VARCHAR(2000),  
			@date_from varchar(10),  
			@date_to varchar(10),  
			@FILENAME_sub VARCHAR(100),  
			@file_from varchar(10),  
			@file_to varchar(10),  
			@jul_from int,  
			@jul_to  int,
			-- START v1.2
			@doc_ctrl_num	VARCHAR(16),  
			@line_value		DECIMAL(20,8), 
			@id				INT,
			@fee			DECIMAL(20,8), 
			-- END v1.2
			-- START v1.3
			@total			DECIMAL(20,8),
			@tot_due		DECIMAL(20,8)
			-- END v1.3

	-- create temp tables  
	create table #buy (  
		ID              int identity(1,1),  
		customer  varchar(8),  
		account_num  varchar(8),  
		child   varchar(12),  
		member_name  varchar(30),  
		issue   varchar(3),    
		discount  varchar(4),  
		type   varchar(1),  
		invoice   varchar(12),  
		split   varchar(3),  
		invoice_date varchar(8),    
		terms   varchar(3),  
		bill_mon  varchar(2),  
		bill_year  varchar(4),  
		merch   varchar(13),  
		non_merch  varchar(13),    
		freight   varchar(11),  
		tax    varchar(11),  
		misc   varchar(13),  
		non_disc  varchar(13),  
		total   varchar(13),  
		mer_disc  varchar(13),  
		tot_due   varchar(13),  
		inv_seq   varchar(2),  
		terms_code  varchar(8))  
  
	create index idx_customer on  #buy (customer) with fillfactor = 80  
	create index idx_invoice on  #buy (invoice) with fillfactor = 80  
	create index idx_id on #buy(ID)
  
	create table #buy_out (  
		ID              int,  
		customer  varchar(8),	 -- 1-8
		account_num  varchar(8), -- 9-16
		child   varchar(12),	 -- 17-28
		member_name  varchar(30), -- 29-58
		issue   varchar(3),		-- 59-61
		discount  varchar(4),	 -- 62-65
		type   varchar(1),		 -- 66
		invoice   varchar(12),		-- 67-78
		split   varchar(3),		 -- 79-81
		invoice_date varchar(8),  -- 82-89  
		terms   varchar(3),		 -- 90-92
		bill_mon  varchar(2),	 -- 93-94 
		bill_year  varchar(4),   -- 95-98
		merch   varchar(12),	 -- 99-110
		non_merch  varchar(12),  -- 111-122
		freight   varchar(10),  -- 123-132
		tax    varchar(10),		-- 133-142
		misc   varchar(12),		-- 143-154,
		non_disc  varchar(12),  -- 155-166
		total   varchar(12),	-- 167-178
		mer_disc  varchar(12),  -- 179-190
		tot_due   varchar(12),  -- 191-202
		inv_seq   varchar(2),   -- 203-204
		terms_code  varchar(8))  
 
	create index idx_customer on  #buy_out (customer) with fillfactor = 80  
	create index idx_invoice on  #buy_out (invoice) with fillfactor = 80  
	create index idx_id on #buy_out (ID)
  
	create table #customer (  
		ID              int identity(1,1),  
		customer  varchar(8))  

	create index idx_customer on  #customer (customer) with fillfactor = 80  
  
	create table #invoice (  
		ID              int identity(1,1),  
		mcount   int,  
		customer  varchar(8),  
		child   varchar(12),   
		invoice   varchar(12),  
		type   varchar(1))  

	create index idx_customer on  #invoice (customer) with fillfactor = 80  
	create index idx_invoice on  #invoice (invoice) with fillfactor = 80  
 
	--=======================================================================  
	IF (CHARINDEX ('Between',@WHERECLAUSE) = 0 )  
	BEGIN  
		--TEMPORARY FOR NOW  
		SELECT  @date_from = convert(varchar(10), dateadd(m,-1, getdate()),101),  
			@date_to = convert(varchar(10), getdate(),101)  
	END		
	ELSE  
	BEGIN  
		SELECT  @date_from = substring(@WHERECLAUSE,charindex('BETWEEN ',@WHERECLAUSE)+9,10), --charindex('AND',@WHERECLAUSE)-1),  
			@date_to = substring(@WHERECLAUSE,charindex('AND ',@WHERECLAUSE)+5,10)     --, charindex('ORDER BY',@WHERECLAUSE)-1)  
	END   
    
	set @jul_from = datediff(dd, '1/1/1753', @date_from) + 639906   
	set @jul_to = datediff(dd, '1/1/1753', @date_to) + 639906   
    
	set @file_from = replace (convert(varchar(12), dateadd(dd, @jul_from - 639906, '1/1/1753'),102),'.','')    
	set @file_to = replace (convert(varchar(12), dateadd(dd, @jul_to - 639906, '1/1/1753'),102),'.','')   
  
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
	Declare	@sequence_num   smallint,  
			@fin_sequence_id  int,   
			@fin_max_sequence_id int,  
			@customer    varchar(8),  
			@child     varchar(12),  
			@invoice    varchar(12),  
			@type     varchar(1),  
			@pcount     int,  
			@mer_disc    varchar(12),  
			@max_count    int,  
			@inv_sequence_id  int,   
			@inv_max_sequence_id int,  
			@invoice_date   varchar(8),  
			@invoice_date_part  varchar(12),  
			@customer_code   varchar(12),  
			@terms_code    varchar(8),  
			@date_doc    int,  
			@date_due    int  

	-- v1.5 Start
	CREATE TABLE #raw_bg_data (
		record_type			varchar(1),
		customer			varchar(8),
		account_num			varchar(10),
		invoice				varchar(12),
		order_num			varchar(8),
		po_num				varchar(8),
		invoice_date		varchar(8),
		ship_to_name		varchar(36),
		ship_to_address		varchar(36),
		ship_to_address2	varchar(36),
		ship_to_city		varchar(20),
		ship_to_state		varchar(2),
		ship_to_zip			varchar(10),
		ship_to_phone		varchar(15),
		ship_via_desc		varchar(20),
		terms_desc			varchar(20),
		sub_total			varchar(12),
		freight				varchar(12),
		tax					varchar(12),
		total				varchar(12),
		line_num			varchar(3),
		item_no				varchar(16),
		item_desc1			varchar(36),
		item_desc2			varchar(36),
		item_desc3			varchar(36),
		qty_shipped			varchar(20))

	CREATE TABLE #raw_bg_data_header (
		parent			varchar(10),
		parent_name		varchar(40),
		cust_code		varchar(10),
		customer_name	varchar(40),
		doc_ctrl_num	varchar(16),
		trm				int,
		type			varchar(14),
		inv_date		varchar(12),
		inv_tot			float,
		mer_tot			float,
		net_amt			int,
		freight			float,
		tax				float,
		mer_disc		float,
		inv_due			float,
		disc_perc		float,
		due_year_month	varchar(7),
		xinv_date		int)

	INSERT	#raw_bg_data
	EXEC dbo.cvo_bg_data_extract_sp @WHERECLAUSE
	-- v1.5
    
	insert into #buy  -- Invoices
	select	left(v.parent,8) customer,   
			left(rtrim(ltrim(isnull(c.ftp,''))),8) account_num,  
			left(rtrim(ltrim(v.cust_code)),12) child,  
			left(c.customer_name,30) member_name,  
			'000' as issue,  
			case when v.disc_perc >=0 then
				right(replace(convert(varchar(20),convert(money,round(v.disc_perc*100,2))),'.',''),4)
				else 0 end as discount,  
			case when left(v.type,1) = 'I' then 'D'  
				else left(v.type,1) end as type,  
			-- 092612 tag  
			case when datalength(v.doc_ctrl_num)>12 then -- installment invoices too long 092612  
				replace(v.doc_ctrl_num,'INV','')   
				ELSE V.DOC_CTRL_NUM END as invoice,  
			'000' as split,  
			right(v.inv_date,4) + left(v.inv_date,2) + convert(char(2),substring(v.inv_date,4,2)) as invoice_date,  
			v.trm as terms,  
			right(v.due_year_month,2) as bill_mon,  
			left(v.due_year_month,4) as bill_year,  
			case when v.disc_perc <= 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2)))   -- net
				else convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2))) end as merch,  
			case when v.disc_perc = 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
				else '0.00' end as non_merch,  
			convert(varchar(11),convert(money,round(sum((v.freight)),2)))  as freight,   
			convert(varchar(11),convert(money,round(sum((v.tax)),2))) as tax,  
			'000000000000' as misc,  
			'000000000000' as non_disc,   
			convert(varchar(13),convert(money, round(sum(v.mer_tot),2)+round(sum(v.freight),2) + round(sum(v.tax),2) )) as total,
			convert(varchar(13),convert(money,round(sum((v.mer_disc)),2))) as mer_disc,
			convert(varchar(13),convert(money,round(sum((v.inv_due)),2))) as tot_due,  
			convert(varchar(2),0) as inv_seq,  
			'' as terms_code  
	from	#raw_bg_data_header v -- v1.5
	join	arcust b (nolock)on v.parent = b.customer_code  
	join	arcust c (nolock)on v.cust_code = c.customer_code  
	where	left(v.type,1) = 'I'  
	and		xinv_date between  @jul_from and @jul_to   
	and		b.addr_sort1 = 'Buying Group'  
	and		v.disc_perc <> 1 -- 053013 - don't include 100% discount items
	group by v.parent,  
			c.ftp,  
			v.cust_code,  
			c.customer_name,  
			v.disc_perc,  
			v.doc_ctrl_num,  
			v.inv_date,  
			v.due_year_month,  
			v.trm,  
			v.type  
	order by v.parent,v.cust_code, v.doc_ctrl_num, v.disc_perc  

	-- v1.9 Start
	CREATE TABLE #install_rounding (
		doc_ctrl_num	varchar(16), 
		inv_gross		decimal(20,8), 
		inv_freight		decimal(20,8), 
		inv_tax			decimal(20,8), 
		inv_net			decimal(20,8), 
		disc_perc		float, 
		rowid			int,
		ar_tot			decimal(20,8), -- v2.0
		ar_diff			decimal(20,8)) -- v2.0

	INSERT	#install_rounding (doc_ctrl_num, inv_gross, inv_freight, inv_tax, inv_net, disc_perc, rowid)
	SELECT	doc_ctrl_num, SUM(inv_tot), SUM(freight), SUM(tax), SUM(inv_due), disc_perc, 0
	FROM	#raw_bg_data_header
	WHERE	CHARINDEX('-',doc_ctrl_num) > 0
	AND		freight = 0
	AND		tax = 0
	GROUP BY doc_ctrl_num, disc_perc

	SELECT	invoice, discount, MAX(id) id
	INTO	#temprecs
	FROM	#buy
	WHERE	CHARINDEX('-',invoice) > 0
	AND		freight = '0.00'
	AND		tax = '0.00'
	GROUP BY invoice, discount

	UPDATE	a
	SET		rowid = b.id
	FROM	#install_rounding a
	JOIN	#temprecs b
	ON		a.doc_ctrl_num = b.invoice
	AND		CAST(CAST(a.disc_perc * 10000 as int) as varchar(10)) = b.discount

	DROP TABLE #temprecs

	CREATE INDEX #install_rounding_ind0 ON #install_rounding(doc_ctrl_num)

	DECLARE @curr_doc varchar(16),
			@inv_gross decimal(20,8),
			@doc_ext int

	SET @doc_ctrl_num = ''

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @doc_ctrl_num = doc_ctrl_num,
				@doc_ext = CAST(RIGHT(doc_ctrl_num,1) as int),
				@inv_gross = inv_gross
		FROM	#install_rounding
		WHERE	doc_ctrl_num > @doc_ctrl_num
		ORDER BY doc_ctrl_num ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		IF ((@doc_ext % 2) = 1)
		BEGIN
			IF ((@inv_gross % 0.01) > 0)
			BEGIN
				IF ((@inv_gross % 0.01) = 0.005)
				BEGIN
					UPDATE	#install_rounding
					SET		inv_gross = ROUND((inv_gross + 0.001),2),
							inv_net = ROUND((inv_net + 0.001),2)
					WHERE	doc_ctrl_num = @doc_ctrl_num
				END
				ELSE
				BEGIN
					UPDATE	#install_rounding
					SET		inv_gross = ROUND((inv_gross),2),
							inv_net = ROUND((inv_net),2)
					WHERE	doc_ctrl_num = @doc_ctrl_num
				END
			END
		END

		IF ((@doc_ext % 2) = 0)
		BEGIN
			IF ((@inv_gross % 0.01) > 0)
			BEGIN
				IF ((@inv_gross % 0.01) = 0.005)
				BEGIN
					UPDATE	#install_rounding
					SET		inv_gross = ROUND((inv_gross - 0.001),2),
							inv_net = ROUND((inv_net - 0.001),2)
					WHERE	doc_ctrl_num = @doc_ctrl_num
				END
				ELSE
				BEGIN
					UPDATE	#install_rounding
					SET		inv_gross = ROUND((inv_gross),2),
							inv_net = ROUND((inv_net),2)
					WHERE	doc_ctrl_num = @doc_ctrl_num
				END
			END
		END
	END

	UPDATE	a
	SET		merch = convert(varchar(13),convert(money,b.inv_gross)), 
			total =  convert(varchar(13),convert(money,b.inv_gross)), 
			mer_disc =  convert(varchar(13),convert(money,b.inv_net)), 
			tot_due = convert(varchar(13),convert(money,b.inv_net))
	FROM	#buy a
	JOIN	#install_rounding b
	ON		a.invoice = b.doc_ctrl_num
	AND		a.id = b.rowid
	-- v1.9 End
	
	-- v2.0 Start
	UPDATE	a
	SET		ar_tot = b.amt_net - (b.amt_tax + b.amt_freight)
	FROM	#install_rounding a
	JOIN	artrx_all b (NOLOCK)
	ON		a.doc_ctrl_num = b.doc_ctrl_num

	UPDATE	#install_rounding
	SET		ar_diff = ar_tot - inv_net

	UPDATE	#install_rounding
	SET		inv_gross = inv_gross + ar_diff,
			inv_net = inv_net + ar_diff	
			
	UPDATE	a
	SET		merch = convert(varchar(13),convert(money,b.inv_gross)), 
			total =  convert(varchar(13),convert(money,b.inv_gross)), 
			mer_disc =  convert(varchar(13),convert(money,b.inv_net)), 
			tot_due = convert(varchar(13),convert(money,b.inv_net))
	FROM	#buy a
	JOIN	#install_rounding b
	ON		a.invoice = b.doc_ctrl_num
	-- v2.0 End

	DROP TABLE #install_rounding
	-- v1.7 End
  
	insert into #buy  -- Credits
	select	left(v.parent,8) customer,   
			left(rtrim(ltrim(isnull(c.ftp,''))),8) account_num,  
			left(rtrim(ltrim(v.cust_code)),12) child,  
			left(c.customer_name,30) member_name,  
			'000' as issue,  
			case when v.disc_perc >=0 then
				right(replace(convert(varchar(20),convert(money,round(v.disc_perc*100,2))),'.',''),4)
				else 0 end as discount,  
			case when left(v.type,1) = 'I' then 'D'  
				else left(v.type,1) end as type,  
			-- 092612 tag  
			case when datalength(v.doc_ctrl_num)>12 then -- installment invoices too long 092612  
				replace(v.doc_ctrl_num,'INV','')   
				ELSE V.DOC_CTRL_NUM END as invoice,  
			'000' as split,  
			right(v.inv_date,4) + left(v.inv_date,2) + convert(char(2),substring(v.inv_date,4,2)) as invoice_date,  
			v.trm as terms,  
			right(v.due_year_month,2) as bill_mon,  
			left(v.due_year_month,4) as bill_year,  
			case when v.disc_perc <= 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2)))   
				else convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2))) end as merch, 
			case when v.disc_perc = 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
				else '0.00' end as non_merch,   
			convert(varchar(11),convert(money,round(abs(sum(v.freight)),2)))  as freight,   
			convert(varchar(11),convert(money,round(abs(sum(v.tax)),2))) as tax,  
			'000000000000' as misc,
			'000000000000' as non_disc,
			convert(varchar(13),convert(money, round(abs(sum(v.mer_tot)),2)+round(Abs(sum(v.freight)),2) + round(abs(sum(v.tax)),2) )) as total,  
			convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2))) as mer_disc,  
			convert(varchar(13),convert(money,round(abs(sum(v.inv_due)),2))) as tot_due,  
			convert(varchar(2),0) as inv_seq,  
			'' as terms_code  
	from	#raw_bg_data_header v -- v1.5
	join	arcust b (nolock)on v.parent = b.customer_code  
	join	arcust c (nolock)on v.cust_code = c.customer_code  
	where	left(v.type,1) <> 'I'  
	and		xinv_date between  @jul_from and @jul_to   
	and		b.addr_sort1 = 'Buying Group'  
	and		v.disc_perc <> 1 -- 053013 - don't include 100% discount items
	group by  v.parent,  
			c.ftp,  
			v.cust_code,  
			c.customer_name,  
			v.disc_perc,  
			v.doc_ctrl_num,  
			v.inv_date,  
			v.due_year_month,  
			v.trm,  
			v.type
	order by v.parent,v.cust_code, v.doc_ctrl_num, v.disc_perc 

	--=================================================================================================  
	-- remove 100% discounts  
	delete from #buy  
	where round(freight,2) = 0  
	and round(tax,2) = 0  
	and round(tot_due,2) = 0  
	and round(mer_disc,2) = 0
	and round(misc,2) = 0
	and round(non_disc,2) = 0
	and round(merch,2) = 0
	and round(non_merch,2) = 0    
	and round(total,2) = 0

	-- tag - 071013
	update #buy set merch = '0.00' where discount = 0 and merch <> '0.00' and non_merch <> '0.00'

	-- update results  
	update #buy  
	set		#buy.terms_code = c.terms_code  
	from	#buy   
	join	orders_invoice i (nolock) on #buy.invoice = i.doc_ctrl_num  
	join	orders_all o (nolock) on i.order_no = o.order_no and i.order_ext = o.ext  
	join	arcust c (nolock) on o.cust_code = c.customer_code   
	where	#buy.terms_code <> c.terms_code
  
	update	#buy  
	set		#buy.terms_code = h.terms_code  
	from	#buy    
	join	artrx_all h (nolock) on h.doc_ctrl_num = #buy.invoice   
	where	#buy.terms_code = ''  
  
	-- recalculate due dates --- why?????????????????  only do for doc's that don't already have one
	-- fill in the blanks in case due date missing
	create table #id_duedate (
		invoice varchar(12),
		new_due_date int,
		bill_year varchar(4),
		bill_mon varchar(2))

	declare @bill_year varchar(4), @bill_mon varchar(2)

	select   @invoice = min(invoice) from #buy where (bill_year = '' or bill_mon = '') and #buy.terms_code not like 'INS%'  
                      
	WHILE (@invoice is not null)
	Begin  
		select @invoice
	
		select  top 1 @customer_code = child,  
				@terms_code = case when type = 'c' then 'NET30' else terms_code end,  
				@invoice_date = invoice_date,  
				@invoice_date_part = substring(@invoice_date,5,2) + '/' + right(@invoice_date,2) + '/' + left(@invoice_date,4),     @date_doc = datediff(dd, '1/1/1753', @invoice_date_part) + 639906  
		from	#buy (nolock)  
		where	invoice = @invoice    
 
		exec CVO_CalcDueDate_sp  @customer_code, @date_doc, @date_due  OUTPUT, @terms_code  
  
		select @bill_year = convert(varchar(4),datepart(yy,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)))

		SELECT @BILL_MON = 	
			case when datepart(dd,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)) <= '25'  
			then right('000'+ convert(varchar(2),datepart(mm,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101))),2)  
			else right('000' + convert(varchar(2),convert(int,datepart(mm,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)))+ 1), 2)  
			end  -- month
    
		insert into #id_duedate values ( @invoice, @date_due, @bill_year, @bill_mon)
	            
		select @invoice = min(invoice) from #buy where invoice > @invoice
			and (bill_year = '' or bill_mon = '') and #buy.terms_code not like 'INS%'  

	End -- while loop  
    
	update	#buy   
	set		#buy.bill_year = due.bill_year,
			#buy.bill_mon =   due.bill_mon
	from		#id_duedate due
	inner join #buy on due.invoice = #buy.invoice 
	and		#buy.terms_code not like 'INS%'  
	and ( #buy.bill_year <> due.bill_year or #buy.bill_mon <>   due.bill_mon )
	    
    drop table #id_duedate
    
	--=========================================================================================  
	-- update row id for same invoice  
    
	If exists ( select count(ID) from #BUY group by customer, child, invoice, type having count(ID) > 1)  
	begin  
  
		truncate table #invoice  
  
		insert into #invoice     
		select count(ID) as mcount, customer, child, invoice, type   
		from #BUY   
		group by customer, child, invoice, type  
		having count(ID) > 1  
  
        select	@fin_sequence_id = '',   
				@fin_max_sequence_id = ''  
  
	    select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
        from #invoice (nolock)  
                      
        WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
        Begin  
              
			select @customer = customer, @child = child, @invoice = invoice, @type = type  
			from #invoice (nolock)   
			where ID = @fin_sequence_id  
     
			select @inv_sequence_id ='',  
				@inv_max_sequence_id ='',  
				@max_count = 0  
  
			select @inv_sequence_id = min(ID), @inv_max_sequence_id = max(ID)   
			from #buy   
			where invoice = @invoice  
			and customer = @customer  
			and child = @child  
			and type = @type  
                 
			WHILE (@inv_sequence_id <= @inv_max_sequence_id )    
            Begin   
        
				set @max_count = @max_count + 1  
        
				update #BUY  
				set inv_seq = convert(varchar(2), @max_count)  
				where ID = @inv_sequence_id  
     
				set @inv_sequence_id = @inv_sequence_id + 1  
			end -- invoice while  
  
     
			set @fin_sequence_id = @fin_sequence_id + 1  
     
		End -- while loop       
	end -- having count(ID) > 1  
  
  
	--=========================================================================================		
	-- update row id for INSTALMENTS  
    
	If exists ( select count(ID) from #BUY  where terms_code like 'INS%' group by customer, child, invoice, type)  
	begin  
  
		truncate table #invoice  
	
		insert into #invoice     
		select count(ID) as mcount, customer, child, invoice, type   
		from #BUY   
		where terms_code like 'INS%'  
		group by customer, child, invoice, type  
     
        select @fin_sequence_id = '',   
            @fin_max_sequence_id = ''  
  
        select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
            from #invoice (nolock)           
                      
        WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
        begin  
			set @invoice = ''  
            set @child = ''  
              
            select @invoice = invoice, @child = child  
            from #invoice (nolock)  
            where ID = @fin_sequence_id  
              
            update #Buy  
            set   
			-- tag 092514 - fix for installment with no -01 ...
			split = case when charindex('-',@invoice) > 0 then
			right('000'+ substring(@invoice,charindex('-',@invoice)+1,len(@invoice)-charindex('-',@invoice)),3)  
			else '001' end
			where invoice = @invoice  
			and child = @child  
     
			set @fin_sequence_id = @fin_sequence_id + 1  
     
		End -- while loop        
	end -- having count(ID) > 1  
  
	--=========================================================================================  
  
	-- return data to explorer view  
	--/*  
  
	SELECT	customer,   
			account_num,   
			child,          
			member_name,                      
			issue,   
			discount,   
			type,   
			invoice,        
			split,   
			invoice_date,   
			terms,   
			bill_mon,   
			bill_year,   
			merch,          
			non_merch,      
			freight,      
			tax,          
			misc,           
			non_disc,       
			total,          
			mer_disc,       
			tot_due,        
			inv_seq  
			,terms_code  --testing remove this  
	from	#buy  
  
	--*/  
	--=========================================================================================  
	-- prep and pad fields for export  
  
	update	#buy 
	set		merch = convert(varchar(12),left(convert(varchar(14),convert(money,merch)*100),len(convert(varchar(14),convert(money,merch)*100))-3)),  
			non_merch = convert(varchar(12),left(convert(varchar(14),convert(money,non_merch)*100),len(convert(varchar(14),convert(money,non_merch)*100))-3)),  
			tax = convert(varchar(10),left(convert(varchar(12),convert(money,tax)*100),len(convert(varchar(14),convert(money,tax)*100))-3)),  
			freight = convert(varchar(10),left(convert(varchar(12),convert(money,freight)*100),len(convert(varchar(14),convert(money,freight)*100))-3)),  
			total = convert(varchar(12),left(convert(varchar(14),convert(money,total)*100),len(convert(varchar(14),convert(money,total)*100))-3)),  
			mer_disc = convert(varchar(12),left(convert(varchar(14),convert(money,mer_disc)*100),len(convert(varchar(14),convert(money,mer_disc)*100))-3)),  
			tot_due = convert(varchar(12),left(convert(varchar(14),convert(money,tot_due)*100),len(convert(varchar(14),convert(money,tot_due)*100))-3))  
  
	update #BUY  
	set		customer =  left(customer + '        ',8),  
			account_num =  right('000000000'+ account_num,8),  
			child = left(child + '            ',12),  
			member_name = left(member_name + '                              ' ,30),  
			issue = right('000'+ issue,3),  
			discount = right('0000' + discount,4),  
			invoice = left(invoice + '            ',12),  
			split = right ('000' + split,3),  
			terms = right ( '000' + terms ,3),  
			merch = right( '000000000000' + merch, 12),  
			non_merch = right( '000000000000' + non_merch, 12),  
			tax = right( '0000000000' + tax, 10),  
			freight = right( '0000000000' + freight, 10),  
			total = right('000000000000' + total,12),   
			mer_disc = right('000000000000' + mer_disc, 12),   
			tot_due = right('000000000000' + tot_due, 12),   
			inv_seq = right('000' + inv_seq, 2),  
			bill_mon = right('00' + bill_mon, 2),
			-- START v1.2
			non_disc = CASE non_disc WHEN '000000000000' THEN '000000000000' ELSE RIGHT( '0000000000' + REPLACE(non_disc,'.',''), 12) END 
			--non_disc = right( '0000000000' + REPLACE(non_disc,'.',''), 10)  -- v1.1 
			-- END v1.2
   
	--=========================================================================================  
	-- select trans for export  
	select @pcount = 0  
	select @pcount = count(ID) from #buy  
  
	if @pcount > 0 
	begin -- records to export   
	-- #customer  
		insert into #customer  
		select distinct customer from #buy (nolock)  
  
        select	@fin_sequence_id = '',   
				@fin_max_sequence_id = '',  
				@customer = ''  
          
        --EXPORT DATA FILE  
		CREATE TABLE ##EXP1_TEMP (  
			ID INT,  
			LINE VARCHAR(265))  
  
        select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
        from #customer (nolock)  
              
		set @pcount = 0         
		WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
		Begin  
			truncate table #buy_out  
			select @customer = customer   
			from #customer  
			where ID = @fin_sequence_id  
  
			Insert into #buy_out  
			select * from #buy  
			where #buy.customer = @customer  
   
			truncate TABLE ##EXP1_TEMP  
  
			INSERT INTO ##EXP1_TEMP (LINE)  
			select	customer +   
					account_num +  
					child +          
					member_name +                      
					issue +   
					discount +   
					type +   
					invoice +        
					split +   
					invoice_date +   
					terms +   
					bill_mon +   
					bill_year +   
					merch +          
					non_merch +      
					freight +      
					tax +          
					misc +           
					non_disc +       
					total +          
					mer_disc +       
					tot_due +        
					inv_seq  
			from	#buy_out  
			order by invoice, inv_seq  
  
 
			SET NOCOUNT ON  
			set @FILENAME_sub = ltrim(rtrim(@customer)) + '_' + @file_from + '_' + @file_to + '.txt'  
			SET @FILENAME = '\\cvo-fs-01\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub  
--			SET @FILENAME = 'C:\Epicor_BGData\Detail\' + @FILENAME_sub  
			--SET @FILENAME = '\\172.20.10.5\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub  
			SET @BCPCOMMAND = 'BCP "SELECT LINE FROM CVO..##EXP1_TEMP" QUERYOUT "'  
			-- SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -U sa -P sa12345  -c'  
			SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -T   -c'  
			EXEC MASTER..XP_CMDSHELL @BCPCOMMAND  
   
			set @fin_sequence_id = @fin_sequence_id + 1    
		end -- while loop  
  
		drop table ##EXP1_TEMP  
	end -- records to export   
  
	--=======================================================================================  
  
	drop table #buy  
	drop table #buy_out  
	drop table #customer 
 
	--=============================================================================  
  
	exec CVO_buying_group_export_two_sp @WHERECLAUSE  
  
	--=============================================================================  
end
GO
GRANT EXECUTE ON  [dbo].[CVO_buying_group_export_sp] TO [public]
GO
