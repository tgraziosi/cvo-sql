SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVOProcessVouchers_sp]    	@debug_level smallint = 0

AS
	DECLARE @result int,
			@current_date		int,
			@trx_ctrl_num		varchar(16),
			@vouch_ctrl_num		varchar(16),
		   	@doc_ctrl_num		varchar(16),	
		   	@user_trx_type_code varchar(8),	
		   	@po_ctrl_num		varchar(16),
		   	@vend_order_num		varchar(20),	
		   	@ticket_num			varchar(20),	
		   	@date_applied		int,
		   	@date_aging			int,
		   	@date_due			int, 	
		   	@date_doc			int,
		   	@date_entered		int,
		   	@date_received		int,
		   	@date_required		int,	
		   	@date_discount		int,	
		   	@posting_code		varchar(8),
		   	@vendor_code		varchar(12),
		   	@pay_to_code		varchar(8),	
		   	@branch_code		varchar(8),
		   	@class_code			varchar(8),		
		   	@approval_code		varchar(8),	
		   	@comment_code		varchar(8),   
		   	@fob_code			varchar(8),		
		   	@terms_code			varchar(8),	
		   	@tax_code			varchar(8),
		   	@recurring_code		varchar(8),	
		   	@location_code		varchar(8),	
		   	@payment_code		varchar(8),
		   	@times_accrued		smallint,	
			@accrual_flag		smallint,	
		   	@drop_ship_flag		smallint,
		   	@add_cost_flag		smallint,
		   	@recurring_flag		smallint,
		   	@one_time_vend_flag	smallint, 
		   	@one_check_flag		smallint,     
		   	@amt_discount		float,   
		   	@amt_tax			float,            
		   	@amt_freight		float,
		   	@amt_misc			float,
			@amt_gross			float,
		   	@amt_net			float,
		   	@amt_due			float,
			@amt_tax_included	float,
			@frt_calc_tax		float,
		   	@doc_desc			varchar(40),
		   	@user_id			smallint,		
		   	@next_serial_id		int,
		   	@pay_to_addr1		varchar(40),   
		   	@pay_to_addr2		varchar(40),
		   	@pay_to_addr3		varchar(40),
		   	@pay_to_addr4		varchar(40),
		   	@pay_to_addr5		varchar(40),
		   	@pay_to_addr6		varchar(40),
		   	@attention_name		varchar(40), 
		   	@attention_phone	varchar(30),	
		   	@intercompany_flag	smallint,
		   	@company_code		varchar(8),   	
		   	@cms_flag			smallint,	
			@nat_cur_code		varchar(8),
			@rate_type_home		varchar(8),
			@rate_type_oper		varchar(8),
			@rate_home			float,
			@rate_oper			float,

			@sequence_id		int,	
			@item_code			varchar(30),	
			@bulk_flag			smallint,	
			@qty_ordered		float,   
			@qty_received		float,
			@code_1099			varchar(8),     
			@unit_code			varchar(8),              
			@unit_price			float,    
			@amt_extended		float,
			@calc_tax			float,
			@gl_exp_acct		varchar(32),   
			@new_gl_exp_acct	varchar(32),        
			@rma_num			varchar(20),
			@line_desc			varchar(60),
			@serial_id			int,
			@company_id 		smallint,
			@rec_company_code	varchar(8), 
			@new_rec_company_code varchar(8),
			@reference_code		varchar(32), 
			@new_reference_code varchar(32),

			@tax_type_code 		varchar(8),
			@amt_taxable		float,	
			@amt_final_tax		float,
			@home_cur_code		varchar(8),
			@oper_cur_code		varchar(8),
			@net_original_amt	float,					 
			@org_id			varchar(30),
			@amt_nonrecoverable_tax	float,			
			@tax_sequence_id	integer,		
			@detail_sequence_id	integer,		
			@recoverable_flag	integer,		
			@account_code		varchar(32),		
			@tax_freight_no_recoverable float,
			@amt_tax_det		float


			DECLARE @voheader TABLE(
						trx_ctrl_num		varchar(16),
						date_applied		int,
						date_aging			int,
						date_due			int,
						date_doc			int,
						date_entered		int,
						date_received		int,
						date_required		int,
						date_recurring		int,
						date_discount		int,
						terms_code			varchar(8),
						recurring_code		varchar(8),
						nat_cur_code		varchar(8),
						rate_type_home		varchar(8),
						rate_type_oper		varchar(8),
						rate_home			float,
						rate_oper			float,
						mark_flag           smallint NULL
						)


			DECLARE @vodetail TABLE(
						trx_ctrl_num           varchar(16),
						sequence_id            int,
						location_code          varchar(8),
						item_code              varchar(30),
						bulk_flag              smallint,
						qty_ordered            float,
						qty_received           float,
						approval_code  		   varchar(8),
						tax_code               varchar(8),
						code_1099              varchar(8),
						po_ctrl_num            varchar(16),
						unit_code              varchar(8),
						unit_price             float,
						amt_discount           float,
						amt_freight            float,
						amt_tax                float,
						amt_misc               float,
						amt_extended           float,
						calc_tax	           float,
						date_entered           int,
						gl_exp_acct            varchar(32),
						rma_num                varchar(20),
						line_desc              varchar(60),
						serial_id              int,
						company_id             smallint,
						rec_company_code       varchar(8),
						reference_code 		   varchar(32),
						org_id			varchar(30) NULL,
						amt_nonrecoverable_tax	float NULL,		
						amt_tax_det		float NULL,
						mark_flag              smallint NULL
						)

			DECLARE  @voaging TABLE (
						trx_ctrl_num 	varchar(16),
						sequence_id		int,
						date_applied 	int,
						date_due		int,
						date_aging		int,
						amt_due			float,
						mark_flag       smallint NULL
						)

			DECLARE @votax TABLE  (
						trx_ctrl_num	varchar(16),
						sequence_id		int,
						tax_type_code	varchar(8),
						amt_taxable		float,
						amt_gross		float,
						amt_tax			float,
						amt_final_tax	float,
						mark_flag       smallint NULL
						)

			DECLARE @votaxdtl TABLE  (
						trx_ctrl_num		varchar(16),
						sequence_id		integer,
						trx_type		integer,
						tax_sequence_id		integer,
						detail_sequence_id	integer,
						tax_type_code		varchar(8),
						amt_taxable		float,
						amt_gross		float,
						amt_tax			float,
						amt_final_tax		float,
						recoverable_flag	integer,
						account_code		varchar(32),
						mark_flag       	smallint NULL
						)

			DECLARE @rates TABLE(	from_currency varchar(8),
				   		to_currency varchar(8),
				  		 rate_type varchar(8),
				 		  date_applied int,
				  		 rate float)



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvopv.cpp" + ", line " + STR( 264, 5 ) + " -- ENTRY: "


EXEC appdate_sp @current_date OUTPUT
SELECT @company_code = company_code,
	   @company_id = company_id,
	   @home_cur_code = home_currency,
	   @oper_cur_code = oper_currency
	   FROM glco




























































































































































--INSERT #voheader (
--rev 2.1
INSERT @voheader (
						trx_ctrl_num,
						date_applied,
						date_aging,
						date_due,
						date_doc,
						date_entered,
						date_received,
						date_required,
						date_recurring,
						date_discount,
						terms_code,
						recurring_code,
						nat_cur_code,
						rate_type_home,
						rate_type_oper,
						rate_home,
						rate_oper,
						mark_flag
						)
SELECT					trx_ctrl_num,
						date_applied,
						date_aging,
						date_due,
						date_doc,
						date_entered,
						date_received,
						date_required,
						date_recurring,
						date_discount,
						terms_code,
						recurring_code,
						nat_cur_code,
						rate_type_home,
						rate_type_oper,
						0.0,
						0.0,
					 	0
FROM #apvochg_work 
WHERE recurring_flag > 0





--UPDATE #voheader 
UPDATE @voheader 
SET date_recurring = a.date_applied + 1
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 1

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = a.date_applied + 7
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 2

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = 

			datediff(dd,"1/1/1800",
			
			dateadd(dd,14,
			
			dateadd(dd,
			
			- datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) + 1
			
			,dateadd(dd,a.date_applied - 657072,"1/1/1800") 
			)
			)
			)+657072



--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 3
AND datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) < 15

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = 
			datediff(dd,"1/1/1800",
			
			dateadd(mm,1,
			
			dateadd(dd,
			
			- datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) + 1
			
			,dateadd(dd,a.date_applied - 657072,"1/1/1800") 
			)
			)
			)+657072
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 3
AND datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) >= 15

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = datediff(dd,"1/1/1800",(dateadd(mm,1,dateadd(dd,a.date_applied - 657072,"1/1/1800"))))+657072
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 4

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = a.date_applied + b.number
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 5

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = a.date_applied + (b.number * 7)
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 6

--UPDATE #voheader 
UPDATE @voheader
SET date_recurring = (datediff(dd,"1/1/1800",(dateadd(mm,b.number,dateadd(dd,a.date_applied - 657072,"1/1/1800"))))+657072)    
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND b.cycle_type = 7



--UPDATE #voheader
UPDATE @voheader
SET date_due = date_due + (date_recurring - date_applied),
    date_doc = date_doc + (date_recurring - date_applied),
	date_entered = date_entered + (date_recurring - date_applied),
	date_received = date_received + (date_recurring - date_applied),
	date_required = date_required + (date_recurring - date_applied),
	date_discount = date_discount + (date_recurring - date_applied),
	date_aging = (date_aging + (date_recurring - date_applied)) * SIGN(date_aging),
	date_applied = date_recurring

--DELETE #voheader
DELETE @voheader
--FROM #voheader a, apcycle b
FROM @voheader a, apcycle b
WHERE a.recurring_code = b.cycle_code
AND (b.cancel_flag > 0 AND a.date_recurring > b.date_cancel)

--UPDATE #voheader
UPDATE @voheader
SET date_due = b.date_due,
    date_discount = b.date_discount
--FROM #voheader a, apterms b
FROM @voheader a, apterms b
WHERE a.terms_code = b.terms_code
AND b.terms_type = 3











IF @@error <> 0
   RETURN -1

--INSERT #rates  (from_currency,
INSERT @rates (from_currency,
				to_currency,
				rate_type,
				date_applied,
				rate)
SELECT DISTINCT nat_cur_code,
				@home_cur_code,
				rate_type_home,
				date_applied,
				0.0
FROM @voheader
--FROM #voheader


--INSERT #rates  (from_currency,
INSERT @rates  (from_currency,
				to_currency,
				rate_type,
				date_applied,
				rate)
SELECT DISTINCT nat_cur_code,
				@oper_cur_code,
				rate_type_oper,
				date_applied,
				0.0
FROM @voheader
--FROM #voheader
				




UPDATE @rates
SET rate = 0.0
WHERE rate != 0.0

UPDATE @rates
SET rate = 1.0
WHERE from_currency = to_currency




declare @rate_info  table (from_currency varchar(8),
			   to_currency varchar(8),
			   rate_type varchar(8),
			   date_applied int,
		           divide_flag smallint,
			   convert_date int)


insert into @rate_info
SELECT a.from_currency,
	   a.to_currency,
	   a.rate_type,
	   a.date_applied,
	   b.divide_flag,
	   convert_date = max(c.convert_date)
FROM @rates a, CVO_Control..mccurate b, CVO_Control..mccurtdt c    
WHERE a.from_currency = b.from_currency
AND a.to_currency = b.to_currency
AND a.from_currency = c.from_currency
AND a.to_currency = c.to_currency
AND a.rate_type = c.rate_type
AND a.rate = 0.0
AND a.date_applied BETWEEN c.convert_date AND c.convert_date + c.valid_for_days
GROUP BY a.from_currency, a.to_currency, a.rate_type, a.date_applied, b.divide_flag


UPDATE @rates
SET rate = c.buy_rate
FROM @rates a, @rate_info b, CVO_Control..mccurtdt c
WHERE a.from_currency = b.from_currency
AND a.to_currency = b.to_currency
AND a.rate_type = b.rate_type
AND a.date_applied = b.date_applied
AND b.from_currency = c.from_currency
AND b.to_currency = c.to_currency
AND b.rate_type = c.rate_type
AND b.convert_date = c.convert_date




--UPDATE #voheader
UPDATE @voheader
SET rate_home = b.rate
--FROM #voheader a, #rates b
FROM @voheader a, @rates b
WHERE a.nat_cur_code = b.from_currency
AND b.to_currency = @home_cur_code
AND a.rate_type_home = b.rate_type
AND a.date_applied = b.date_applied

--UPDATE #voheader
UPDATE @voheader
SET rate_oper = b.rate
--FROM #voheader a, #rates b
FROM @voheader a, @rates b
WHERE a.nat_cur_code = b.from_currency
AND b.to_currency = @oper_cur_code
AND a.rate_type_oper = b.rate_type
AND a.date_applied = b.date_applied

--DROP TABLE #rates


    
--INSERT #vodetail (
INSERT @vodetail (
					trx_ctrl_num,
					sequence_id,
					location_code,
					item_code,
					bulk_flag,
					qty_ordered,
					qty_received,
					approval_code,
					tax_code,
					code_1099,
					po_ctrl_num,
					unit_code,
					unit_price,
					amt_discount,
					amt_freight,
					amt_tax,
					amt_misc,
					amt_extended,
					calc_tax,
					date_entered,
					gl_exp_acct,
					rma_num,
					line_desc,
					serial_id,
					company_id,
					rec_company_code,
					reference_code,
					org_id,
					mark_flag,
					amt_nonrecoverable_tax,
					amt_tax_det
     				)
SELECT 
					a.trx_ctrl_num,
					a.sequence_id,
					a.location_code,
					a.item_code,
					a.bulk_flag,
					a.qty_ordered,
					a.qty_received,
					a.approval_code,
					a.tax_code,
					a.code_1099,
					a.po_ctrl_num,
					a.unit_code,
					a.unit_price,
					a.amt_discount,
					a.amt_freight,
					a.amt_tax,
					a.amt_misc,
					a.amt_orig_extended,
					a.calc_tax,
					a.date_entered,
					a.gl_exp_acct,
					a.rma_num,
					a.line_desc,
					a.serial_id,
					a.company_id,
					a.rec_company_code,
					a.reference_code,
					a.org_id,
					0,
					a.amt_nonrecoverable_tax,
					a.amt_tax_det
--FROM #apvocdt_work a, #voheader b
FROM #apvocdt_work a, @voheader b
WHERE a.trx_ctrl_num = b.trx_ctrl_num


--INSERT #voaging
INSERT @voaging
			(
				trx_ctrl_num,
				sequence_id,
				date_applied,
				date_due,
				date_aging,
				amt_due,
				mark_flag
			)
SELECT			a.trx_ctrl_num,
				a.sequence_id,
				b.date_recurring,
				a.date_due + b.date_recurring - a.date_applied,
				a.date_aging + b.date_recurring - a.date_applied,
				a.amt_due,
				0
--FROM  #apvoage_work a, #voheader b
FROM #apvoage_work a, @voheader b
WHERE a.trx_ctrl_num = b.trx_ctrl_num


--UPDATE #voaging
UPDATE @voaging
SET date_due = c.date_due
--FROM #voaging a, #voheader b, apterms c 
FROM @voaging a, @voheader b, apterms c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND b.terms_code = c.terms_code
AND c.terms_type = 3
AND a.sequence_id = 1

--INSERT #votax (
INSERT @votax(
				trx_ctrl_num,
				sequence_id,
				tax_type_code,
				amt_taxable,
				amt_gross,
				amt_tax,
				amt_final_tax,
				mark_flag
			  )
SELECT			a.trx_ctrl_num,
				a.sequence_id,
				a.tax_type_code,
				a.amt_taxable,
				a.amt_gross,
				a.amt_tax,
				a.amt_final_tax,
				0
--FROM #apvotax_work a, #voheader b
FROM #apvotax_work a, @voheader b
WHERE a.trx_ctrl_num = b.trx_ctrl_num

--INSERT #votaxdtl (
INSERT @votaxdtl(
				trx_ctrl_num,
				sequence_id,
				trx_type,
				tax_sequence_id,
				detail_sequence_id,
				tax_type_code,
				amt_taxable,
				amt_gross,
				amt_tax,
				amt_final_tax,
				recoverable_flag,
				account_code,
				mark_flag
				)
SELECT				a.trx_ctrl_num,
				a.sequence_id,
				a.trx_type,
				a.tax_sequence_id,
				a.detail_sequence_id,
				a.tax_type_code,
				a.amt_taxable,
				a.amt_gross,
				a.amt_tax,
				a.amt_final_tax,
				a.recoverable_flag,
				a.account_code,
				0
--FROM #apvotaxdtl_work a, #voheader b
FROM #apvotaxdtl_work a, @voheader b
WHERE a.trx_ctrl_num = b.trx_ctrl_num

WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT 	   
			@trx_ctrl_num =				TEMP.trx_ctrl_num,
		   	@doc_ctrl_num =				WRK.doc_ctrl_num,
		   	@user_trx_type_code =		WRK.user_trx_type_code,
		   	@po_ctrl_num =				WRK.po_ctrl_num,
		   	@vend_order_num =			WRK.vend_order_num,
		   	@ticket_num =				WRK.ticket_num,	
		   	@date_applied =				TEMP.date_applied,
		   	@date_aging =				TEMP.date_aging,	
		   	@date_due =					TEMP.date_due, 	
		   	@date_doc =					TEMP.date_doc,
		   	@date_entered =				TEMP.date_entered,	
		   	@date_received =			TEMP.date_received,	
		   	@date_required =			TEMP.date_required,	
		   	@date_discount =			TEMP.date_discount,	
		   	@posting_code =				WRK.posting_code,
		   	@vendor_code =				WRK.vendor_code,	
		   	@pay_to_code =				WRK.pay_to_code,	
		   	@branch_code =				WRK.branch_code,
		   	@class_code =				WRK.class_code,		
		   	@approval_code =			WRK.approval_code,	
		   	@comment_code =				WRK.comment_code,   
		   	@fob_code =					WRK.fob_code,		
		   	@terms_code =				TEMP.terms_code,	
		   	@tax_code =					WRK.tax_code,
		   	@recurring_code =			TEMP.recurring_code,	
		   	@location_code =			WRK.location_code,	
		   	@payment_code =				WRK.payment_code,
		   	@times_accrued =			WRK.times_accrued,	
			@accrual_flag =				WRK.accrual_flag,	
		   	@drop_ship_flag =			WRK.drop_ship_flag, 
		   	@add_cost_flag =			WRK.add_cost_flag, 
		   	@recurring_flag =			WRK.recurring_flag,
		   	@one_time_vend_flag =		WRK.one_time_vend_flag, 
		   	@one_check_flag =			WRK.one_check_flag,     
		   	@amt_gross =				WRK.amt_gross,	
		   	@amt_discount =				WRK.amt_discount,   
		   	@amt_tax =					WRK.amt_tax,            
		   	@amt_freight =				WRK.amt_freight,	
		   	@amt_misc =					WRK.amt_misc,       
		   	@amt_net =					WRK.amt_net,            
		   	@amt_due =					WRK.amt_due,
			@amt_tax_included =			WRK.amt_tax_included,
			@frt_calc_tax =				WRK.frt_calc_tax,
		   	@doc_desc =					WRK.doc_desc,	
		   	@user_id =					user_id,		
		   	@next_serial_id =			WRK.next_serial_id,
		   	@pay_to_addr1 =				WRK.pay_to_addr1,   
		   	@pay_to_addr2 =				WRK.pay_to_addr2,       
		   	@pay_to_addr3 =				WRK.pay_to_addr3,	
		   	@pay_to_addr4 =				WRK.pay_to_addr4,   
		   	@pay_to_addr5 =				WRK.pay_to_addr5,       
		   	@pay_to_addr6 =				WRK.pay_to_addr6,	
		   	@attention_name =			WRK.attention_name, 
		   	@attention_phone =			WRK.attention_phone,	
		   	@intercompany_flag =		WRK.intercompany_flag,
		   	@company_code =				WRK.company_code,   	
		   	@cms_flag =					WRK.cms_flag,
			@nat_cur_code =				TEMP.nat_cur_code,
			@rate_type_home =			TEMP.rate_type_home,
			@rate_type_oper =			TEMP.rate_type_oper,
			@rate_home =				TEMP.rate_home,
			@rate_oper =				TEMP.rate_oper,
			@net_original_amt =			WRK.net_original_amt,
			@org_id		=				WRK.org_id,
			@tax_freight_no_recoverable = WRK.tax_freight_no_recoverable
--		  FROM #voheader
		  FROM @voheader TEMP
			INNER JOIN #apvochg_work WRK ON TEMP.trx_ctrl_num = WRK.trx_ctrl_num
		  WHERE TEMP.mark_flag = 0

	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

			SELECT @vouch_ctrl_num = NULL	      
	
			EXEC @result = apvocrh_sp
				4000,
				2,	
				@vouch_ctrl_num OUTPUT,
			   	4091,		
			   	@doc_ctrl_num,	
			   	"",
			   	@user_trx_type_code,	
			   	"",		
			   	@po_ctrl_num,
			   	@vend_order_num,	
			   	@ticket_num,	
			   	@date_applied,
			   	@date_aging,	
			   	@date_due, 	
			   	@date_doc,
			   	@date_entered,	
			   	@date_received,	
			   	@date_required,	
			   	0,			
			   	@date_discount,	
			   	@posting_code,
			   	@vendor_code,	
			   	@pay_to_code,	
			   	@branch_code,
			   	@class_code,		
			   	@approval_code,	
			   	@comment_code,   
			   	@fob_code,		
			   	@terms_code,	
			   	@tax_code,
			   	@recurring_code,	
			   	@location_code,	
			   	@payment_code,
			   	@times_accrued,	
			   	@accrual_flag,	
			   	@drop_ship_flag, 
			   	0,  
			   	1, 
			   	@add_cost_flag, 
			   	0,      
			   	@recurring_flag,
			   	@one_time_vend_flag, 
			   	@one_check_flag,     
			   	@amt_gross,	
			   	@amt_discount,   
			   	@amt_tax,            
			   	@amt_freight,	
			   	@amt_misc,       
			   	@amt_net,            
			   	0.0, 
			   	@amt_due,
			   	0.0,        
				@amt_tax_included,
				@frt_calc_tax,
			   	@doc_desc,	
			   	"",
			   	@user_id,		
			   	@next_serial_id,
			   	@pay_to_addr1,   
			   	@pay_to_addr2,       
			   	@pay_to_addr3,	
			   	@pay_to_addr4,   
			   	@pay_to_addr5,       
			   	@pay_to_addr6,	
			   	@attention_name, 
			   	@attention_phone,	
			   	@intercompany_flag,
			   	@company_code,   	
			   	@cms_flag,	
				"",
				@nat_cur_code,
				@rate_type_home,
				@rate_type_oper,
				@rate_home,
				@rate_oper,
				@net_original_amt,
				@org_id,
				@tax_freight_no_recoverable
			   	
   			
   			IF  (@result != 0)
				RETURN @result

			




			EXEC @result = APVOPsaReTrx_sp
							@trx_ctrl_num,
							@vouch_ctrl_num		
					
   			IF  (@result != 0)
			RETURN @result

			



		 
			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
								@location_code = location_code,
								@item_code = item_code,	
								@bulk_flag = bulk_flag,	
								@qty_ordered = qty_ordered,   
								@qty_received = qty_received,  
								@approval_code = approval_code, 
								@tax_code = tax_code,	
								@code_1099 = code_1099,     
								@po_ctrl_num = po_ctrl_num,   
								@unit_code = unit_code,              
								@unit_price = unit_price,    
								@amt_discount = amt_discount,  
								@amt_freight = amt_freight,            
								@amt_tax = amt_tax,       
								@amt_misc = amt_misc,      
								@amt_extended = amt_extended,           
								@calc_tax = calc_tax,           
								@date_entered = date_entered,  
								@gl_exp_acct = gl_exp_acct,   
								@rma_num = rma_num,       
								@line_desc = line_desc,     
								@serial_id = serial_id,              
								@company_id = company_id,    
								@rec_company_code = rec_company_code, 
								@reference_code = reference_code,
								@org_id	= org_id,
								@amt_nonrecoverable_tax = amt_nonrecoverable_tax,
								@amt_tax_det = amt_tax_det
						--FROM #vodetail
						FROM @vodetail
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocrd_sp
							4000,	
							2,	
							@vouch_ctrl_num,
							4091,	
							@sequence_id,	
							@location_code,
							@item_code,	
							@bulk_flag,	
							@qty_ordered,   
							@qty_received,  
							0.0,	
							0.0,      
							@approval_code, 
							@tax_code,	
							"",            
							@code_1099,     
							@po_ctrl_num,   
							@unit_code,              
							@unit_price,    
							@amt_discount,  
							@amt_freight,            
							@amt_tax,       
							@amt_misc,      
							@amt_extended,           
							@calc_tax,           
							@date_entered,  
							@gl_exp_acct,   
							"",        
							@rma_num,       
							@line_desc,     
							@serial_id,              
							@company_id,    
							1,  
							0,
							@rec_company_code, 
							"",
							@reference_code, 
							"",
							@org_id,
							@amt_nonrecoverable_tax,
							@amt_tax_det

					IF(@result != 0)
						RETURN @result


				SET ROWCOUNT 1
				--UPDATE #vodetail
				UPDATE @vodetail
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND mark_flag = 0
				SET ROWCOUNT 0

			END



		
			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
								@date_applied = date_applied,
								@date_due = date_due,	
								@date_aging = date_aging,	
								@amt_due = amt_due
--						FROM #voaging
						FROM @voaging
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocra_sp 
									4000,	
									2,		
									@vouch_ctrl_num,
									4091,	
									@sequence_id,		
									@date_applied,
									@date_due,	
									@date_aging,	
									@amt_due

			IF(@result != 0)
				RETURN @result


				SET ROWCOUNT 1
--				UPDATE #voaging
				UPDATE @voaging
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND mark_flag = 0
				SET ROWCOUNT 0

			END



	   
			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
								@tax_type_code = tax_type_code,
								@amt_taxable = amt_taxable,				
								@amt_gross = amt_gross,	
								@amt_tax = amt_tax,
								@amt_final_tax = amt_final_tax
--						FROM #votax
						FROM @votax
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocrt_sp
										4000,	
										2,	
										@vouch_ctrl_num,
										4091,	
										@sequence_id,	
										@tax_type_code,
										@amt_taxable,	
										@amt_gross,	
										@amt_tax,
										@amt_final_tax

			IF(@result != 0)
				RETURN @result


				SET ROWCOUNT 1
--				UPDATE #votax
				UPDATE @votax
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND mark_flag = 0
				SET ROWCOUNT 0

			END

	   
			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
							@tax_sequence_id = tax_sequence_id,
							@detail_sequence_id = detail_sequence_id,
							@tax_type_code = tax_type_code,
							@amt_taxable = amt_taxable,
							@amt_gross = amt_gross,
							@amt_tax = amt_tax,
							@amt_final_tax = amt_final_tax,
							@recoverable_flag = recoverable_flag,
							@account_code = account_code
--						FROM #votaxdtl
						FROM @votaxdtl
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocrtdt_sp
										@vouch_ctrl_num,
										4091,	
										@sequence_id,
										@tax_sequence_id,
										@detail_sequence_id,
										@tax_type_code,
										@amt_taxable,
										@amt_gross,
										@amt_tax,
										@amt_final_tax,
										@recoverable_flag,
										@account_code

			IF(@result != 0)
				RETURN @result


				SET ROWCOUNT 1
--				UPDATE #votaxdtl
				UPDATE @votaxdtl
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND mark_flag = 0
				SET ROWCOUNT 0

			END

			SET ROWCOUNT 1
--			UPDATE #voheader		    
			UPDATE @voheader
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

--DROP TABLE #voheader
--DROP TABLE #vodetail
--DROP TABLE #voaging
--DROP TABLE #votax
--DROP TABLE #votaxdtl

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvopv.cpp" + ", line " + STR( 1319, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOProcessVouchers_sp] TO [public]
GO
