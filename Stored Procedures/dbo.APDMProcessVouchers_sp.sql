SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMProcessVouchers_sp]    	@debug_level smallint = 0

AS
	DECLARE @result int,
			@current_date int,
			@trx_ctrl_num varchar(16),
			@vouch_ctrl_num varchar(16),
			@doc_ctrl_num varchar(16),
			@user_trx_type_code varchar(16),
 			@po_ctrl_num varchar(16),
 			@vend_order_num varchar(32),
 			@ticket_num varchar(20),
 			@date_applied int,
 			@date_doc int,
			@date_due int,
 			@date_entered int,
 			@posting_code varchar(8), 
 			@vendor_code varchar(12),
 			@pay_to_code varchar(8),
 			@branch_code varchar(8),
 			@class_code	varchar(8),
 			@approval_code varchar(8),
 			@comment_code varchar(8),
 			@fob_code varchar(8),
 			@terms_code varchar(8),
 			@tax_code varchar(8),
 			@location_code varchar(8),
			@payment_code varchar(8),
 			@amt_restock float,
 		    @doc_desc varchar(40),
 			@user_id int,
 			@attention_name	varchar(40),   
 			@attention_phone varchar(40),   
 			@company_code varchar(8),
		   	@restock_acct_code varchar(32),   
		 	@company_id int,
			@nat_cur_code varchar(8),
			@rate_type_home varchar(8),
			@rate_type_oper varchar(8),
			@rate_home float,
			@rate_oper float,
			@home_cur varchar(8),
			@oper_cur varchar(8),
			@org_id	varchar(30), 				
			@tax_freight_no_recoverable float,
			@str_msg varchar(255)


declare @ib_offset smallint, @ib_seg smallint, @ib_length smallint, @segment_length smallint, @ib_flag smallint

select @ib_offset = ib_offset, @ib_seg = ib_segment, @ib_length = ib_length, @ib_flag = ib_flag from glco

--select @segment_length = ISNULL(sum(length),0) from glaccdef where acct_level < @ib_seg
-- scr 38330

  select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg 

-- end 38330


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpv.cpp" + ", line " + STR( 105, 5 ) + " -- ENTRY: "


EXEC appdate_sp @current_date OUTPUT
SELECT @company_code = company_code,
	   @company_id = company_id,
	   @home_cur = home_currency,
	   @oper_cur = oper_currency
	    FROM glco


--CREATE TABLE #voheader (
DECLARE @voheader TABLE (
						trx_ctrl_num varchar(16),
						doc_ctrl_num varchar(16),
						user_trx_type_code varchar(16),
			 			po_ctrl_num varchar(16),
			 			vend_order_num varchar(32),
			 			ticket_num varchar(20), 
			 			date_applied int,
			 			date_aging int,
						date_due int,
			 			date_doc int,
			 			posting_code varchar(8), 
			 			vendor_code varchar(12),
			 			pay_to_code varchar(8),
			 			branch_code varchar(8),
			 			class_code	varchar(8),
			 			approval_code varchar(8),
			 			comment_code varchar(8),
			 			fob_code varchar(8),
			 			terms_code varchar(8),
			 			tax_code varchar(8),
			 			location_code varchar(8),
						payment_code varchar(8),
			 			amt_restock float,
			 		    doc_desc varchar(40),
			 			user_id int,
			 			attention_name	varchar(40),   
			 			attention_phone varchar(40),   
					   	restock_acct_code varchar(32),   
						nat_cur_code varchar(8),
						rate_type_home varchar(8),
						rate_type_oper varchar(8),
						rate_home float,
						rate_oper float,
						mark_flag smallint,
						org_id	varchar(30) NULL,			
						tax_freight_no_recoverable float
						)



--INSERT #voheader (
insert @voheader(
						trx_ctrl_num,
						doc_ctrl_num,
						user_trx_type_code,
			 			po_ctrl_num,
			 			vend_order_num,
			 			ticket_num,
			 			date_applied,
			 			date_aging,
						date_due,
			 			date_doc,
			 			posting_code,
			 			vendor_code,
			 			pay_to_code,
			 			branch_code,
			 			class_code,
			 			approval_code,
			 			comment_code,
			 			fob_code,
			 			terms_code,
			 			tax_code,
			 			location_code,
						payment_code,
			 			amt_restock,
			 		    doc_desc,
			 			user_id,
			 			attention_name,
			 			attention_phone,
					   	restock_acct_code,
						nat_cur_code,
						rate_type_home,
						rate_type_oper,
						rate_home,
						rate_oper,
						mark_flag,
						org_id,					
						tax_freight_no_recoverable
						)
SELECT   	a.trx_ctrl_num,
			a.doc_ctrl_num,
			c.user_trx_type_code,
			a.po_ctrl_num,
			a.vend_order_num,
			a.ticket_num,
			a.date_applied,
			a.date_doc,
			0,
			a.date_doc,
			a.posting_code,
			a.vendor_code,
			a.pay_to_code,
			a.branch_code,
			a.class_code,
			a.approval_code,
			a.comment_code,
			a.fob_code,
			a.terms_code,
			a.tax_code,
			a.location_code,
			c.payment_code,
			a.amt_restock,
			a.doc_desc,
			a.user_id,
			a.attention_name,
			a.attention_phone,
			CASE WHEN @ib_flag = 0 THEN b.restock_acct_code
				ELSE STUFF(b.restock_acct_code,@ib_offset + @segment_length ,@ib_length, d.branch_account_number) END, 
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			0.0,
			0.0,
		 	0,
			a.org_id,							
			a.tax_freight_no_recoverable
FROM #apdmchg_work a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN apmaster c ON a.vendor_code = c.vendor_code
		INNER JOIN Organization d ON a.org_id = d.organization_id
WHERE c.address_type = 0
AND ((a.amt_restock) > (0.0) + 0.0000001)


















CREATE TABLE #apterms
(
 date_doc int,
 terms_code varchar(8),
 date_due int,
 date_discount int
)


INSERT #apterms (
	 date_doc,
	 terms_code,
	 date_due,
	 date_discount
	 )
SELECT DISTINCT
	   date_doc,
	   terms_code,
	   0,
	   0
FROM @voheader
--FROM #voheader

EXEC apterms_sp

--UPDATE #voheader
UPDATE @voheader
SET date_due = b.date_due
FROM @voheader a, #apterms b
WHERE a.terms_code = b.terms_code
AND a.date_doc = b.date_doc


--FROM #voheader a, #apterms b
DROP TABLE #apterms


CREATE TABLE #rates (from_currency varchar(8),
				   to_currency varchar(8),
				   rate_type varchar(8),
				   date_applied int,
				   rate float)
IF @@error <> 0
   RETURN -1


INSERT #rates (from_currency,
				 to_currency,
				 rate_type,
				 date_applied,
				 rate)
SELECT DISTINCT nat_cur_code,
		 	    @home_cur,
				rate_type_home,
				date_applied,
			    0.0E0
FROM @voheader
--FROM #voheader


INSERT #rates (from_currency,
				 to_currency,
				 rate_type,
				 date_applied,
				 rate)
SELECT DISTINCT nat_cur_code,
		 	    @oper_cur,
				rate_type_oper,
				date_applied,
			    0.0E0
FROM @voheader
--FROM #voheader

EXEC CVO_Control..mcrates_sp

--UPDATE #voheader

UPDATE @voheader
SET rate_home = b.rate
FROM @voheader a, #rates b
WHERE a.nat_cur_code = b.from_currency
AND b.to_currency = @home_cur
AND a.date_applied = b.date_applied
AND a.rate_type_home = b.rate_type

--FROM #voheader a, #rates b

--UPDATE #voheader
UPDATE @voheader
SET rate_oper = b.rate
--FROM #voheader a, #rates b
FROM @voheader a, #rates b
WHERE a.nat_cur_code = b.from_currency
AND b.to_currency = @oper_cur
AND a.date_applied = b.date_applied
AND a.rate_type_oper = b.rate_type

DROP TABLE #rates

WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT 		@trx_ctrl_num = trx_ctrl_num,
						@doc_ctrl_num = doc_ctrl_num,
						@user_trx_type_code = user_trx_type_code,
			 			@po_ctrl_num = po_ctrl_num,
			 			@vend_order_num = vend_order_num,
			 			@ticket_num = ticket_num,
			 			@date_applied = date_applied,
			 			@date_doc = date_doc,
						@date_due = date_due,
			 			@posting_code = posting_code,
			 			@vendor_code = vendor_code,
			 			@pay_to_code = pay_to_code,
			 			@branch_code = branch_code,
			 			@class_code = class_code,
			 			@approval_code = approval_code,
			 			@comment_code = comment_code,
			 			@fob_code = fob_code,
			 			@terms_code = terms_code,
			 			@tax_code = tax_code,
			 			@location_code = location_code,
						@payment_code = payment_code,
			 			@amt_restock = amt_restock,
			 		    @doc_desc = doc_desc,
			 			@user_id = user_id,
			 			@attention_name = attention_name,
			 			@attention_phone = attention_phone,
			    		@tax_code = tax_code,
					   	@restock_acct_code = restock_acct_code,
						@nat_cur_code = nat_cur_code,
						@rate_type_home = rate_type_home,
						@rate_type_oper = rate_type_oper,
						@rate_home = rate_home,
						@rate_oper = rate_oper,
						@org_id	= org_id,			
						@tax_freight_no_recoverable = tax_freight_no_recoverable
		  FROM @voheader
		  WHERE mark_flag = 0
--		  FROM #voheader
--		  WHERE mark_flag = 0
	  
	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

			SELECT @vouch_ctrl_num = NULL	 

			EXEC appgetstring_sp "STR_RESTOCK_CHARGE", @str_msg OUT     
	
			EXEC @result = apvocrh_sp
					   	4000,
					   	2,
					   	@vouch_ctrl_num  OUTPUT,
						4091,
						@doc_ctrl_num,
						" ",
						@user_trx_type_code,
						" ", 
						@po_ctrl_num,
						@vend_order_num,
						@ticket_num,
						@date_applied,
						@date_doc,
						@date_due,
						@date_doc,
						@current_date,
						0,
						0,
						0,
						0,
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
						"",
						@location_code,
						@payment_code,
						0,
						0,
						0,
						0,
						1,
						0,
						0,
						0,
						0,
						0,
						@amt_restock,
						0,
						0,
						0,
						0,
						@amt_restock,
						0,
						@amt_restock,
					    0,
						0,
						0,
					    @doc_desc,
						@str_msg,		   
						@user_id,
						1,
						"",	   
						"",	   
						"",	   
						"",	   
						"",	   
						"",	   
						@attention_name,   
						@attention_phone,   
						0,
						@company_code,
						0,
						" ",       
						@nat_cur_code,
						@rate_type_home,
						@rate_type_oper,
						@rate_home,
						@rate_oper,	
						0,
						@org_id,			 
						@tax_freight_no_recoverable
   			
   			IF  (@result != 0)
				RETURN @result


				EXEC @result = apvocrd_sp
					   	 4000,
					   	 2,
					   	 @vouch_ctrl_num,
						 4091,
		   				 1,   
		   				 " ",		 		       
		   				 " ",				     
		   				 0,		 			    
	   					 0,					   
	   					 1,					   
	   					 0,					   
						 0,     
		   				 " ",  	 	
		   				 @tax_code, 
	   					 " ",    
	   					 " ",    
	   					 " ",    
	   					 " ",    
		   				 @amt_restock, 
		   				 0,      
	   					 0,    
	   					 0,     
	   					 0,      
	   					 @amt_restock,   
	   					 0,      
		   				 @current_date,   
		   				 @restock_acct_code,   
	   					 " ",    
	   					 " ",              
	   					 @str_msg,   
	   					 1,    
		   				 @company_id,    
		   				 1,         
	   					 0,    
						 @company_code,   
						 " ",
	   					 " ",		
						 " ",
							@org_id  
			
			IF  (@result != 0)
				RETURN @result


			SET ROWCOUNT 1
--			UPDATE #voheader
			UPDATE @voheader					    
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

--DROP TABLE #voheader

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpv.cpp" + ", line " + STR( 541, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMProcessVouchers_sp] TO [public]
GO
