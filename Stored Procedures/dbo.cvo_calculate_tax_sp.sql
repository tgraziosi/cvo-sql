SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 28/06/2013 - Issue #863 - calulcate tax for Discount Adjustment Credit Memo
/* DECLARE @calc_tax DECIMAL(20,8), @err int 
	EXEC cvo_calculate_tax_sp 'NOTAX', 'USD','010125',1,'001',100, @calc_tax OUTPUT, @err OUTPUT
	SELECT @calc_tax, @err  
*/

CREATE PROCEDURE [dbo].[cvo_calculate_tax_sp]	@tax_code VARCHAR(8), 
												@curr_code VARCHAR(8), 
												@cust_code VARCHAR(8), 
												@curr_factor DECIMAL(20,8), 
												@location VARCHAR(10), 
												@amount DECIMAL(20,8), 
												@calc_tax DECIMAL(20,8) OUTPUT,
												@err int OUTPUT
AS       
BEGIN
	SET NOCOUNT ON          

	DECLARE @debug				INT, 
			@tot_ord_tax		DECIMAL(20,8), 
			@tot_ord_incl		DECIMAL(20,8), 
			@ship_ind			INT, 
			@freight			DECIMAL(20,8), 
			@total_tax			DECIMAL(20,8), 
			@non_included_tax	DECIMAL(20,8), 
			@included_tax		DECIMAL(20,8),
			@hstat				CHAR(1),          
			@precision			INT, 
			@xlin				INT, 
			@exprice			DECIMAL(20,8), 
			@exdisc				DECIMAL(20,8),
			@txcode				CHAR(8), 
			@origqty			DECIMAL(20,8), 
			@qty				DECIMAL(20,8),       
			@cpi_count			INT,           
			@calc_method		CHAR(1),
			@tax_companycode	VARCHAR(255),          
			@orders_org_id		VARCHAR(30),
			@row_id				INT,  
			@last_row_id		INT,
			@reference_number	INT, 
			@qty_tx				DECIMAL(20,8),   
			@alloc_qty			DECIMAL(20,8), 
			@cr_ordered			DECIMAL(20,8), 
			@conv_factor		DECIMAL(20,8), 
			@curr_price			DECIMAL(20,8), 
			@discount			DECIMAL(20,8),  
			@ordered			DECIMAL(20,8)  

  
    SET @calc_tax = 0                
        
	select	@cpi_count = 1, 
			@txcode = @tax_code      
	select @ship_ind = 0
                
          
	select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock) -- mls 9/22/03 31913          
	  where flag = 'SO_TAX_CALC_MTHD'),'1')          
        
	create table #TXTaxOutput (  
	  control_number varchar(16) not null,  
	  amtTotal float,  
	  amtDisc float,  
	  amtExemption float,  
	  amtTax float,  
	  remoteDocId int  
	)  
	create index #TTO_1 on #TXTaxOutput( control_number )  
  
	create table #TXTaxLineOutput (  
	  control_number varchar(16) not null,  
	  reference_number int not null,  
	  t_index int,  
	  taxRate float,  
	  taxable float,  
	  taxCode varchar(30),  
	  taxability varchar(10),  
	  amtTax  float,  
	  amtDisc float,  
	  amtExemption float,  
	  taxDetailCnt int,  
	  amtTaxCalculated  float  
	)  
	create index #TTLO_1 on #TXTaxLineOutput( control_number, t_index)  
  
	create table #TXTaxLineDetOutput (  
	  control_number varchar(16) not null,  
	  reference_number int not null,  
	  t_index int,  
	  d_index int,  
	  amtBase float,  
	  exception smallint,  
	  jurisCode varchar(30),  
	  jurisName varchar(255),  
	  jurisType varchar(30),  
	  nonTaxable float,  
	  taxRate float,  
	  amtTax float,  
	  taxable float,  
	  taxType smallint,  
	  amtTaxCalculated  float  
	)  
	create index #TTLDO_1 on #TXTaxLineDetOutput( control_number, t_index, d_index)  
	create index #TTLDO_2 on #TXTaxLineDetOutput( control_number, jurisCode, jurisType)  
	  
	CREATE TABLE #TxLineInput  
	(  
	 control_number  varchar(16),  
	 reference_number int,  
	 tax_code   varchar(8),  
	 quantity   float,  
	 extended_price  float,  
	 discount_amount  float,  
	 tax_type   smallint,  
	 currency_code  varchar(8)  
	)  
	create index #TLI_1 on #TxLineInput( control_number, reference_number)  
  
	CREATE TABLE #TxInfo  
	( control_number  varchar(16), sequence_id  int,  tax_type_code  varchar(8),  
	 amt_taxable  float,  amt_gross  float,  amt_tax   float,  
	 amt_final_tax  float,  currency_code  varchar(8), tax_included_flag smallint )  
	create index #TI_1 on #TxInfo( control_number, sequence_id)  
  
	CREATE TABLE #txconnhdrinput (  
	doccode varchar(16),  
	doctype int,  
	trx_type smallint,  
	companycode  varchar(25),  
	docdate  datetime,  
	exemptionno  varchar(20),  
	salespersoncode  varchar(20),  
	discount  float,  
	purchaseorderno  varchar(20),  
	customercode  varchar(20),  
	customerusagetype  varchar(20) ,  
	detaillevel  varchar(20) ,  
	referencecode  varchar(20) ,  
	oriaddressline1 varchar(40),  
	oriaddressline2 varchar(40) ,  
	oriaddressline3 varchar(40) ,  
	oricity varchar(40) ,  
	oriregion varchar(40) ,  
	oripostalcode varchar(40) ,  
	oricountry varchar(40) ,  
	destaddressline1 varchar(40),  
	destaddressline2 varchar(40) ,  
	destaddressline3 varchar(40) ,  
	destcity varchar(40) ,  
	destregion varchar(40) ,  
	destpostalcode varchar(40) ,  
	destcountry varchar(40) ,  
	currCode varchar(8),  
	currRate decimal(20,8),  
	currRateDate datetime null,  
	locCode varchar(20) null,  
	paymentDt datetime null,  
	taxOverrideReason varchar(20) null,  
	taxOverrideAmt decimal(20,8) null,  
	taxOverrideDate datetime null,  
	taxOverrideType int null,  
	commitInd int null  
	)  
	create index TCHI_1 on #txconnhdrinput( doctype, doccode)  
	create index TCHI_2 on #txconnhdrinput( doccode)  
  
	CREATE TABLE #txconnlineinput (  
	doccode varchar(16),  
	no varchar(20),  
	oriaddressline1 varchar(40),  
	oriaddressline2 varchar(40) ,  
	oriaddressline3 varchar(40) ,  
	oricity varchar(40) ,  
	oriregion varchar(40) ,  
	oripostalcode varchar(40) ,  
	oricountry varchar(40) ,  
	destaddressline1 varchar(40),  
	destaddressline2 varchar(40) ,  
	destaddressline3 varchar(40) ,  
	destcity varchar(40) ,  
	destregion varchar(40) ,  
	destpostalcode varchar(40) ,  
	destcountry varchar(40) ,  
	qty float ,  
	amount float,  
	discounted smallint,   
	exemptionno varchar(20),  
	itemcode varchar(40) ,  
	ref1 varchar(20) ,  
	ref2 varchar(20) ,  
	revacct varchar(20) ,  
	taxcode varchar(8) ,  
	customerUsageType varchar(20) null,  
	description varchar(255) null,  
	taxIncluded int null,  
	taxOverrideReason varchar(20) null,  
	taxOverrideTaxAmount decimal(20,8) null,  
	taxOverrideTaxDate datetime null,  
	taxOverrideType int null  
	)  
	create index TCLI_1 on #txconnlineinput( doccode, no)  
  
	create table #TXLineInput_ex(  
	  row_id int identity,  
	  control_number varchar(16) not null,  
	  reference_number int not null,  
	  trx_type int not null default(0),  
	  currency_code varchar(8),  
	  curr_precision int,  
	  amt_tax decimal(20,8) default(0),  
	  amt_final_tax decimal(20,8) default(0),  
	  tax_code varchar(8),  
	  freight decimal(20,8) default(0),  
	  qty decimal(20,8) default(1),  
	  unit_price decimal(20,8) default(0),  
	  extended_price decimal(20,8) default(0),  
	  amt_discount decimal(20,8) default(0),  
	  err_no int default(0),  
	  action_flag int default(0),  
	  seqid int,  
	  calc_tax decimal(20,8) default(0),  
	  vat_prc decimal(20,8) default(0),  
	  amt_nonrecoverable_tax decimal(20,8) default(0),  
	  amtTaxCalculated decimal(20,8) default(0))  
	create index TXti1 on #TXLineInput_ex(control_number,row_id)  
	create index TXti2 on #TXLineInput_ex(control_number, reference_number)  
	create index TXti3 on #TXLineInput_ex(row_id)  
  
	create table #TXtaxtype (  
	  row_id int identity,  
	  ttr_row int,  
	  tax_type varchar(8),  
	  ext_amt decimal(20,8),  
	  amt_gross decimal(20,8),  
	  amt_taxable decimal(20,8),  
	  amt_tax decimal(20,8),  
	  amt_final_tax decimal(20,8),  
	  amt_tax_included decimal(20,8),  
	  save_flag int,  
	  tax_rate decimal(20,8),  
	  prc_flag int,  
	  prc_type int,  
	  cents_code_flag int,  
	  cents_code varchar(8),  
	  cents_cnt int,  
	  tax_based_type int,  
	  tax_included_flag int,  
	  modify_base_prc decimal(20,8),  
	  base_range_flag int,  
	  base_range_type int,  
	  base_taxed_type int,  
	  min_base_amt decimal(20,8),  
	  max_base_amt decimal(20,8),  
	  tax_range_flag int,  
	  tax_range_type int,  
	  min_tax_amt decimal(20,8),  
	  max_tax_amt decimal(20,8),  
	  recoverable_flag int,  
	  dtl_incl_ind int NULL)  
	create index TXtt1 on #TXtaxtype(row_id)  
	create index TXtt2 on #TXtaxtype(ttr_row)  
  
	create table #TXtaxtyperec (  
	  row_id int identity,  
	  tc_row int,  
	  tax_code varchar(8),  
	  seq_id int,  
	  base_id int,  
	  cur_amt decimal(20,8),  
	  old_tax decimal(20,8),  
	  tax_type varchar(8))  
	create index TXttr1 on #TXtaxtyperec(row_id)  
	create index TXttr2 on #TXtaxtyperec(tc_row)  
	create index TXttr3 on #TXtaxtyperec(tax_code, tc_row, seq_id)  
  
	create table #TXtaxcode (  
	  row_id int identity,  
	  ti_row int,  
	  control_number varchar(16),  
	  tax_code varchar(8),  
	  amt_tax decimal(20,8),  
	  tax_included_flag int,  
	  tax_type_cnt int,  
	  tot_extended_amt decimal(20,8))  
	create index TXtc1 on #TXtaxcode(row_id)  
	create index TXtc2 on #TXtaxcode(control_number, tax_code)  
  
	create table #TXcents (  
	  row_id int identity,  
	  cents_code varchar(8),  
	  to_cent decimal(20,8),  
	  tax_cents decimal(20,8))  
  
	create index c1 on #TXcents(cents_code,row_id)  
  
	-- mls 7/29/04 SCR 33324           
	delete from #TxLineInput          
	delete from #TXLineInput_ex          
	delete from #txconnhdrinput          
	delete from #txconnlineinput          
	          
	delete from #TXtaxtype          
	delete from #TXtaxtyperec          
	delete from #TXtaxcode          
	delete from #TXcents          
                   
	select  
		@hstat = 'N',         
		@origqty = 1, 
		@xlin=-1,           
		@qty = 1, 
		@exprice = 0, 
		@exdisc = 0,              
		@freight = 0 ,        
		@orders_org_id = 'CVO'         
	 
          
	select @tax_companycode = isnull((select tc_companycode from Organization_all (nolock) where organization_id = @orders_org_id),'')          
          
	select @precision = isnull( (select curr_precision from glcurr_vw (nolock) where glcurr_vw.currency_code=@curr_code), 1.0 )          
          
	insert #txconnhdrinput          
	(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,          
	discount, purchaseorderno, customercode, customerusagetype, detaillevel,          
	referencecode, oriaddressline1, oriaddressline2, oriaddressline3,          
	oricity, oriregion, oripostalcode, oricountry, destaddressline1,          
	destaddressline2, destaddressline3, destcity, destregion, destpostalcode,          
	destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,          
	taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)          
	select 'ordered', 0, 2032, @tax_companycode, getdate(), '', '',          
	0 , '', @cust_code, '', 3, 
	'',  l.addr1,l.addr2,l.addr3,
	l.city,l.state,l.zip,l.country_code,c.addr2, 
	c.addr3, c.addr4,c.city, c.state, c.postal_code, 
	c.country_code, @curr_code, @curr_factor, getdate(), '', NULL,          
	'', 0.0, NULL, 2, 0          
	from arcust c  (nolock), locations_all l (nolock)        
	where c.customer_code = @cust_code and l.location = @location
          
	if @@error <> 0          
	begin          
	  select @err = -21          
	  return          
	end          
          
	if not exists (select 1 from #txconnhdrinput)          
	begin          
	  select @err = -22          
	  return          
	end          
          
	select @xlin = 0, @ship_ind = 0         
      
	insert #TXLineInput_ex (control_number,          
	reference_number, trx_type, currency_code, curr_precision,          
	tax_code, qty, unit_price, extended_price,          
	amt_discount, seqid, vat_prc)          
	select 'ordered',1, 0, @curr_code, @precision ,      
	@tax_code, 1, @amount, @amount,          
	0, 1, 0       
	 
	 
	CREATE TABLE #aco_line_cursor (  
	row_id    int IDENTITY(1,1),  
	reference_number int,  
	qty     decimal(20,8))  
  
	INSERT #aco_line_cursor (reference_number, qty)  
	SELECT reference_number, qty FROM #TXLineInput_ex  
  
	CREATE INDEX #aco_line_cursor_ind0 ON #aco_line_cursor(row_id)  
  
	SET @last_row_id = 0  
  
	SELECT TOP 1 
		@row_id = row_id,  
		@reference_number = reference_number,  
		@qty_tx = qty  
	FROM #aco_line_cursor  
	WHERE row_id > @last_row_id  
	ORDER BY row_id ASC  
  
	WHILE (@@ROWCOUNT <> 0)  
	BEGIN  
  

		SELECT 
			@cr_ordered  = 0,  
			@conv_factor = 1,  
			@curr_price  = @amount,  
			@discount    = 0,  
			@ordered = 1 
	
  		SET @alloc_qty = @ordered 
          
		SET @qty_tx = (@alloc_qty + @cr_ordered) * @conv_factor  
     
		UPDATE #TXLineInput_ex  
		SET qty = @qty_tx  
			,extended_price = Round( ( (@qty_tx ) * @curr_price ), curr_precision )         
			,amt_discount   = Round( ( Round( ( (@qty_tx ) * @curr_price ), curr_precision ) * @discount/100 ), curr_precision)  
		WHERE  reference_number = @reference_number  
      
		SET @last_row_id = @row_id  
  
		SELECT TOP 1 
			@row_id = row_id,  
			@reference_number = reference_number,  
			@qty_tx = qty  
		FROM #aco_line_cursor  
		WHERE row_id > @last_row_id  
		ORDER BY row_id ASC  
  
	END  
  

	DROP TABLE #aco_line_cursor   
         
	if @@error <> 0           
	begin                  
	  select @err = -2          
	  return          
	end          
          
	select @err = -3          
	       
	insert #txconnlineinput          
	(doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,          
	oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,          
	destaddressline2,  destaddressline3, destcity,  destregion,          
	destpostalcode,  destcountry,  qty,   amount,          
	discounted,   exemptionno,  itemcode,  ref1,          
	ref2,    revacct,  taxcode )          
	select          
	TLI.control_number, TLI.reference_number, oriaddressline1, oriaddressline2, oriaddressline3,          
	oricity, oriregion, oripostalcode, oricountry, CHI.destaddressline1,          
	CHI.destaddressline2, CHI.destaddressline3, CHI.destcity, CHI.destregion, CHI.destpostalcode,          
	CHI.destcountry,  TLI.qty ,TLI.extended_price - TLI.amt_discount,          
	case when amt_discount <> 0 then 1 else 0 end, CHI.exemptionno, 'DISCOUNT ADJUSTMENT', '','', '', TLI.tax_code          
	from #TXLineInput_ex TLI          
	join #txconnhdrinput CHI on CHI.doccode = TLI.control_number                  
	where TLI.action_flag = 0          
          
	if @@error <> 0          
	begin          
	  select @err = -24          
	  return          
	end          
          
     

	select @err = -5          
	          
	exec @err = TXCalculateTax_SP @debug, 1 -- distr_call          
	          
	if @err <> 1           
	begin          
	 select @err = -6          
	 return          
	end          
          
	select @total_tax=0, @non_included_tax=0, @included_tax=0      -- mls 3/28/00 SCR 22705 start          
	select @tot_ord_tax = 0, @tot_ord_incl = 0          
	          
	exec TXGetTotal_SP 'ordered', @tot_ord_tax output, @non_included_tax output, @tot_ord_incl output, @calc_method, 1        
	exec TXGetTotal_SP 'shipped', @total_tax output, @non_included_tax output, @included_tax output, @calc_method, 1       
          
          
	if @total_tax < 0          
	begin          
		select @err = -81          
		return          
	end          
	if @tot_ord_tax < 0          
	begin          
		select @err = -82          
		return          
	end   

	select @calc_tax = calc_tax from #TXLineInput_ex       
    
  
  
	return   
END  
  
GO
GRANT EXECUTE ON  [dbo].[cvo_calculate_tax_sp] TO [public]
GO
