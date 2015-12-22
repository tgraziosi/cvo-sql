SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apchkstb_sp] 		   @print_batch_num int, 
									   @print_acct_num smallint,
									   @payment_memo smallint,
						   			   @voucher_classification smallint,
									   @voucher_comment smallint,
									   @voucher_memo smallint,
									   @history_flag  smallint,
									   @cash_acct_code varchar(32),
									   @process_group_num varchar(16),
									   @debug_level smallint = 0


AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 67, 5 ) + " -- MSG: " + "insert #apchkstb payment type1 voucher records"

	INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
	SELECT b.vendor_code,
	       " ",
		   @cash_acct_code,
		   @print_batch_num,
		   b.trx_ctrl_num,
		   1,
		   @print_acct_num,
		   @payment_memo,
		   @voucher_classification,
		   @voucher_comment,
		   @voucher_memo,
		   b.apply_to_num,
		   b.vo_amt_applied,
		   b.vo_amt_disc_taken,
		   b.vo_amt_applied + b.vo_amt_disc_taken,
		   c.doc_ctrl_num,
		   c.date_doc,
		   c.date_due,
		   "Vchr: " + b.apply_to_num,
		   c.user_trx_type_code,
		   c.doc_desc,
		   isnull(d.comment_line," "),
		   -1,
		   0,
		   0,
		   b.nat_cur_code,
		   1,
		   @history_flag
	FROM   apinppyt a, apinppdt b, apvohdr c LEFT OUTER JOIN apcommnt d ON c.comment_code = d.comment_code
	WHERE  a.trx_ctrl_num = b.trx_ctrl_num
	AND    a.trx_type = b.trx_type
	AND    b.apply_to_num = c.trx_ctrl_num
	AND    a.posted_flag = -1
	AND    a.process_group_num = @process_group_num
	

IF (@@error != 0)
   RETURN -1






	INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
	SELECT b.vendor_code,
	       " ",
		   @cash_acct_code,
		   @print_batch_num,
		   b.trx_ctrl_num,
		   2,
		   @print_acct_num,
		   @payment_memo,
		   @voucher_classification,
		   @voucher_comment,
		   @voucher_memo,
		   b.apply_to_num,
		   b.amt_applied,
		   0.0,
		   b.amt_applied,
		   "",
		   0,
		   0,
		   "(" + b.nat_cur_code + ") Paid as (" + a.nat_cur_code + ")",
		   "",
		   "",
		   "",
		   -1,
		   0,
		   0,
		   a.nat_cur_code,
		   1,
		   @history_flag
	FROM   apinppyt a, apinppdt b, apvohdr c
	WHERE  a.trx_ctrl_num = b.trx_ctrl_num
	AND    a.trx_type = b.trx_type
	AND	   a.nat_cur_code != b.nat_cur_code 
	AND    b.apply_to_num = c.trx_ctrl_num
	AND    a.posted_flag = -1
	AND    a.process_group_num = @process_group_num
	

IF (@@error != 0)
   RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "insert Payment type 7 records--amount on account"

	INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
	SELECT apinppyt.vendor_code,
	       " ",
		   @cash_acct_code,
		   @print_batch_num,
		   apinppyt.trx_ctrl_num,
		   7,
		   @print_acct_num,
		   @payment_memo,
		   @voucher_classification,
		   @voucher_comment,
		   @voucher_memo,
		   " ",
		   apinppyt.amt_on_acct,
		   0.0,
		   apinppyt.amt_on_acct,
		   "OnAcct",
		   0,
		   0,
		   "This portion of payment is on account ",
		   "",
		   "",
		   "",
		   -1,
		   0,
		   0,
		   nat_cur_code,
		   1,
		   @history_flag
	FROM   apinppyt
	WHERE  apinppyt.posted_flag = -1
	AND    apinppyt.process_group_num = @process_group_num
	AND    ((apinppyt.amt_on_acct) > (0.0) + 0.0000001)





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 276, 5 ) + " -- MSG: " + "Load on acct info into temp table"
SELECT a.trx_ctrl_num,
       a.sequence_id,
       a.doc_ctrl_num,
       a.apply_to_num,
       c.vendor_code,
       c.pay_to_code,
       c.payment_type,
       b.amt_applied,
	   c.date_doc,
       payment_num = space(16),
	   pay_cur = c.currency_code,
	   b.vo_amt_applied,
	   b.vo_amt_disc_taken,
	   vo_cur = d.currency_code,
	   mark_flag = 0
INTO #check_onacct       	
FROM apchkdsb a, appydet b, appyhdr c, apvohdr d
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.sequence_id = b.sequence_id
AND a.apply_to_num = b.apply_to_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND b.apply_to_num = d.trx_ctrl_num

AND a.check_num = ""
AND b.void_flag = 0
AND c.void_flag = 0



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 306, 5 ) + " -- MSG: " + "Associate on account records by voucher"



UPDATE #check_onacct
SET #check_onacct.payment_num = #apchkstb.payment_num
FROM #check_onacct, #apchkstb
WHERE #check_onacct.apply_to_num = #apchkstb.voucher_num




UPDATE #check_onacct
SET mark_flag = 1
WHERE payment_num = space(16)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 322, 5 ) + " -- MSG: " + "Associate on account records by vendor-pay_to_code"



UPDATE #check_onacct
SET #check_onacct.payment_num = #check_header.trx_ctrl_num
FROM #check_onacct, #check_header
WHERE #check_onacct.vendor_code = #check_header.vendor_code
AND   #check_onacct.pay_to_code = #check_header.pay_to_code
AND	  #check_onacct.mark_flag = 1





DELETE #check_onacct
WHERE payment_num = space(16)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 341, 5 ) + " -- MSG: " + "Insert on-account payment records"



INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
				SELECT  #check_onacct.vendor_code,
					" ",            
					@cash_acct_code,
					@print_batch_num,
					#check_onacct.payment_num,
					3,
					@print_acct_num,
					@payment_memo,
					@voucher_classification,
					@voucher_comment,
					@voucher_memo,
					#check_onacct.apply_to_num,
					-#check_onacct.amt_applied,
					0,
					-#check_onacct.amt_applied,
					#check_onacct.doc_ctrl_num,
					date_doc,
					0,
					"Pmt:" + #check_onacct.doc_ctrl_num,
					"",
					"" ,
					"" ,
					-1,
					0,
					0,
					pay_cur,
					1,
					@history_flag
			   FROM #check_onacct
			   WHERE #check_onacct.payment_type = 1





INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
				SELECT  #check_onacct.vendor_code,
					" ",            
					@cash_acct_code,
					@print_batch_num,
					#check_onacct.payment_num,
					0,
					@print_acct_num,
					@payment_memo,
					@voucher_classification,
					@voucher_comment,
					@voucher_memo,
					#check_onacct.apply_to_num,
					0,
					0,
					0-#check_onacct.vo_amt_applied,
					"",
					0,
					1,
					"Pmt:" + #check_onacct.doc_ctrl_num+"(" + pay_cur + ") Applied as (" + vo_cur + ")",
					"",
					"" ,
					"" ,
					-1,
					0,
					0,
					vo_cur,
					1,
					@history_flag
			   FROM #check_onacct
			   WHERE #check_onacct.payment_type = 1
			   AND pay_cur <> vo_cur






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 478, 5 ) + " -- MSG: " + "Insert on-account debit memo records"
INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
				SELECT  #check_onacct.vendor_code,
					" ",            
					@cash_acct_code,
					@print_batch_num,
					#check_onacct.payment_num,
					5,
					@print_acct_num,
					@payment_memo,
					@voucher_classification,
					@voucher_comment,
					@voucher_memo,
					#check_onacct.apply_to_num,
					0,
					0,
					0 - #check_onacct.amt_applied,
					#check_onacct.doc_ctrl_num,
					apdmhdr.date_doc,
					0,
					"DbMmo:" + #check_onacct.doc_ctrl_num +
					" (" + apdmhdr.doc_ctrl_num + ")",
					"",
					"",
					"",
					-1,
					0,
					0,
					apdmhdr.currency_code,
					1,
					@history_flag
				FROM #check_onacct,apdmhdr
				WHERE #check_onacct.payment_type = 3
				AND #check_onacct.doc_ctrl_num = apdmhdr.trx_ctrl_num






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 548, 5 ) + " -- MSG: " + "Insert on-account debit memo records"
INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
				SELECT  #check_onacct.vendor_code,
					" ",            
					@cash_acct_code,
					@print_batch_num,
					#check_onacct.payment_num,
					0,
					@print_acct_num,
					@payment_memo,
					@voucher_classification,
					@voucher_comment,
					@voucher_memo,
					#check_onacct.apply_to_num,
					0,
					0,
					0 - #check_onacct.vo_amt_applied,
					"",
					0,
					1,
					"DbMmo:" + #check_onacct.doc_ctrl_num +	"(" + pay_cur + ") Applied as (" + vo_cur + ")",
					"",
					"",
					"",
					-1,
					0,
					0,
					#check_onacct.vo_cur,
					1,
					@history_flag
				FROM #check_onacct,apdmhdr
				WHERE #check_onacct.payment_type = 3
				AND #check_onacct.doc_ctrl_num = apdmhdr.trx_ctrl_num
				AND pay_cur <> vo_cur





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 617, 5 ) + " -- MSG: " + "Insert voucher records for on-accts not matched to a voucher"






SELECT DISTINCT	 payment_num, apply_to_num, vo_amt_applied= sum(vo_amt_applied)
INTO  #temp
FROM #check_onacct
WHERE mark_flag = 1
Group By payment_num, apply_to_num



	INSERT #apchkstb (	vendor_code,
						check_num,
						cash_acct_code,
						print_batch_num,
						payment_num,
						payment_type,
						print_acct_num,
						payment_memo,
						voucher_classification,
						voucher_comment,
						voucher_memo,
						voucher_num,
						amt_paid,
						amt_disc_taken,
						amt_net,
						invoice_num,
						invoice_date,
						voucher_date_due,
						description,
						voucher_classify,
						voucher_internal_memo,
						comment_line,
						posted_flag,
						printed_flag,
						overflow_flag,
						nat_cur_code,
						lines,
						history_flag ) 
	SELECT DISTINCT apvohdr.vendor_code,
	       " ",
		   @cash_acct_code,
		   @print_batch_num,
		   #temp.payment_num,
		   6,
		   @print_acct_num,
		   @payment_memo,
		   @voucher_classification,
		   @voucher_comment,
		   @voucher_memo,
		   #temp.apply_to_num,
		   vo_amt_applied,
		   0.0,
		   vo_amt_applied, 
		   apvohdr.doc_ctrl_num,
		   apvohdr.date_doc,
		   apvohdr.date_due,
		   "Vchr: " + #temp.apply_to_num,
		   apvohdr.user_trx_type_code,
		   apvohdr.doc_desc,
		   isnull(apcommnt.comment_line," "),
		   -1,
		   0,
		   0,
		   apvohdr.currency_code,
		   1,
		   @history_flag
	FROM   #temp, apvohdr LEFT OUTER JOIN apcommnt ON apvohdr.comment_code = apcommnt.comment_code
	WHERE  #temp.apply_to_num = apvohdr.trx_ctrl_num


SELECT b.apply_to_num, vo_amt_disc_taken = SUM(b.vo_amt_disc_taken)
INTO #temp1
FROM #check_onacct b
WHERE ((b.vo_amt_disc_taken) > (0.0) + 0.0000001)
GROUP BY b.apply_to_num

UPDATE #apchkstb
SET amt_disc_taken = a.amt_disc_taken + b.vo_amt_disc_taken,
	amt_net = a.amt_net + b.vo_amt_disc_taken
FROM #apchkstb a, #temp1 b
WHERE a.voucher_num = b.apply_to_num
AND a.payment_type = 1
										


DROP TABLE #temp1
DROP TABLE #temp
DROP TABLE #check_onacct


SELECT b.voucher_num, b.nat_cur_code, amt_net = SUM(amt_net)
INTO #temp2
FROM #apchkstb b
WHERE b.payment_type > 1
GROUP BY b.voucher_num, b.nat_cur_code


UPDATE #apchkstb
SET amt_net = a.amt_net - b.amt_net
FROM #apchkstb a, #temp2 b
WHERE a.voucher_num = b.voucher_num
AND a.nat_cur_code = b.nat_cur_code
AND a.payment_type = 1


DROP TABLE #temp2
































































































































IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkstb.cpp" + ", line " + STR( 858, 5 ) + " -- EXIT: "

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apchkstb_sp] TO [public]
GO
