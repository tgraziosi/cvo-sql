SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvohist_sp] 	@debug_level smallint = 0
	
AS





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvohist.cpp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "


		SELECT  DISTINCT	
				a.trx_ctrl_num,  
				invoice_date = case when a.date_doc < 657072 then NULL else dateadd(dd,a.date_doc-657072,1/1/1800) end,  
				b.apply_to_num,  
				date_due=case when c.date_due < 657072 then NULL else dateadd(dd,c.date_due-657072,1/1/1800) end,  
				b.amt_applied,  
				b.amt_disc_taken,  
				amt_net = b.amt_applied,  
				a.doc_ctrl_num,  
				a.payment_type,   
				d.symbol,  
				d.curr_precision,  
				e.payment_num  
		INTO #apvohist_temp
		FROM  appyhdr a, appydet b, apvohdr c,glcurr_vw d,   #apchkstb   e  
		WHERE a.trx_ctrl_num = b.trx_ctrl_num   
				AND b.apply_to_num = c.trx_ctrl_num  
				AND d.currency_code = a.currency_code  
				AND b.apply_to_num = e.voucher_num  
				AND a.void_flag = 0  
				AND e.history_flag = 1
		ORDER BY invoice_date DESC, a.trx_ctrl_num DESC  ;



		INSERT #apvohist (
				trx_ctrl_num, 
				invoice_num, 
				invoice_date, 
				voucher_num, 
				voucher_date_due, 
				amt_paid, 
				amt_disc_taken, 
				amt_net, 
				doc_ctrl_num, 
				description, 
				payment_type, 
				symbol, 
				curr_precision, 
				voucher_internal_memo, 
				comment_line, 
				voucher_classify, 
				trx_link				 )
		SELECT  DISTINCT	
				b.trx_ctrl_num,  
				'',   
				b.invoice_date ,  
				b.apply_to_num,  
				b.date_due ,  
				b.amt_applied,  
				b.amt_disc_taken,  
				b.amt_applied,  
				b.doc_ctrl_num,  
				'' ,  
				b.payment_type,   
				b.symbol,  
				b.curr_precision,  
				'' ,  
				'' ,  
				'' ,  
				b.payment_num  
		FROM  #apvohist_temp b left outer join #apchkstb   a on
			  a.payment_num = b.payment_num 
			  AND a.invoice_num = b.doc_ctrl_num 
			  AND a.voucher_num = b.apply_to_num 
		WHERE a.payment_num  is null
		ORDER BY b.invoice_date DESC, b.trx_ctrl_num DESC  


		drop table #apvohist_temp


		INSERT #apvohist (
				trx_ctrl_num, 
				invoice_num, 
				invoice_date, 
				voucher_num, 
				voucher_date_due, 
				amt_paid, 
				amt_disc_taken, 
				amt_net, 
				doc_ctrl_num, 
				description, 
				payment_type, 
				symbol, 
				curr_precision, 
				voucher_internal_memo, 
				comment_line, 
				voucher_classify, 
				trx_link				 )
		SELECT DISTINCT a.trx_ctrl_num,
				'',
				invoice_date = case when a.date_doc < 657072 then NULL else dateadd(dd,a.date_doc-657072,1/1/1800) end,
				a.apply_to_num,
				case when a.date_due < 657072 then NULL else dateadd(dd,a.date_due-657072,1/1/1800) end,
				a.amt_paid_to_date,
				a.amt_discount,
				a.amt_paid_to_date,
				a.doc_ctrl_num,
				'',
				1,
				b.symbol,
				b.curr_precision,
				'',
				'',
				'',
				c.payment_num
		FROM  apvohdr a, glcurr_vw b, #apchkstb c  
		WHERE a.trx_ctrl_num <> a.apply_to_num
				AND b.currency_code = a.currency_code 
				AND a.apply_to_num = c.voucher_num  
				AND c.history_flag = 1






	
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvohist_sp] TO [public]
GO
