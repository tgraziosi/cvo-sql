SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/  

create procedure [dbo].[apaccrualsupdaterec_sp]  
	@accrual_number varchar(16)
	as
		begin
			CREATE TABLE #receipts_tmp (
		      tmp_ctrl_num  varchar(16))

 	INSERT INTO #receipts_tmp(tmp_ctrl_num) SELECT distinct trx_ctrl_num FROM accrualsdet t
			WHERE t.accrual_number = @accrual_number
			AND t.to_post_flag=1
			AND t.trans_type =4

	/* CREA LAS TABLAS DE REGRESO DE DATOS EQUIVALENTES A apinptax Y apinptaxdtl */
	
		CREATE TABLE #tmpinptax(
		       timestamp timestamp NOT NULL,
		       documenttype varchar(20) NOT NULL,
		       trx_ctrl_num varchar(16) NOT NULL,
		       trx_type smallint NOT NULL,
		       sequence_id int NOT NULL,
		       tax_type_code varchar(8) NOT NULL,
		       amt_taxable float NOT NULL,
		       amt_gross float NOT NULL,
		       amt_tax float NOT NULL,
		       amt_final_tax float NOT NULL ) 
	
	 
	
		CREATE TABLE #tmpinptaxdtl(
		       timestamp timestamp NOT NULL,
		       trx_ctrl_num varchar(16) NOT NULL,
		       sequence_id int NOT NULL,
		       trx_type int NOT NULL,
		       tax_sequence_id int NOT NULL,
		       detail_sequence_id int NOT NULL,
		       tax_type_code varchar(8) NOT NULL,
		       amt_taxable float NOT NULL,
		       amt_gross float NOT NULL,
		       amt_tax float NOT NULL,
		       amt_final_tax float NOT NULL,
		       recoverable_flag int NOT NULL,
		       account_code varchar(32) NOT NULL )
	
			 
			exec apaccrualsreceiptstax_sp
			
			create table #apvocdt_tmp (
			 trx_ctrl_num varchar(30),
			 amt_extended float,
			 tax_code varchar(8),
			 calc_tax float	)

			 insert into #apvocdt_tmp
			 SELECT  receipts.receipt_no as trx_ctrl_num,isnull(receipts.unit_cost * receipts.quantity,0) as amt_extended,pur_list.tax_code, 
			 isnull(pur_list.total_tax,0) as calc_tax
			 FROM receipts
				 join releases (nolock) on ( receipts.po_no = releases.po_no ) and
						( receipts.po_line = releases.po_line ) and
						( receipts.release_date = releases.release_date )			
				 join pur_list_rcvg_vw pur_list (nolock) on ( pur_list.po_no = releases.po_no ) and  
			         ( pur_list.part_no = releases.part_no ) and  
			         ( pur_list.line = releases.po_line )
			    join purchase_rcvg_vw purchase (nolock) on ( pur_list.po_no = purchase.po_no )
			    left outer join inv_master (nolock) on ( pur_list.part_no = inv_master.part_no)
			    join accrualsdet (nolock) on cast(receipts.receipt_no as char(16)) = accrualsdet.trx_ctrl_num
			   WHERE --( receipts.receipt_batch_no = 1 ) 
				--   AND
			 	accrualsdet.to_post_flag=1
			       AND accrualsdet.trans_type = 4 
			       AND accrualsdet.accrual_number = @accrual_number
			       AND receipts.status = 'R'
			       AND accrualsdet.posted_flag IS NULL	 	 	
			ORDER BY receipts.receipt_no ASC, pur_list.po_no ASC,   
			         pur_list.line ASC 
 
			UPDATE #apvocdt_tmp 
		 	SET #apvocdt_tmp.calc_tax = dt1.sumtax
			from #apvocdt_tmp t join
			(SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 4 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 on t.trx_ctrl_num = dt1.trx_ctrl_num 
			 --AND t.posted_flag IS NULL
			
			
			UPDATE	#apvocdt_tmp
			SET	amt_extended = #apvocdt_tmp.amt_extended - #apvocdt_tmp.calc_tax
			FROM 	#apvocdt_tmp, aptax c
			WHERE 	#apvocdt_tmp.tax_code = c.tax_code
			AND 	c.tax_included_flag = 1


			 UPDATE accrualsdet 
			 SET total_amt = dt.sumcol + dt.sumtax 
			 FROM accrualsdet t JOIN 
			 (SELECT  ad.trx_ctrl_num,isnull(sum(ad.amt_extended),0) as sumcol, isnull(sum(ad.calc_tax),0) as sumtax 
			 FROM #apvocdt_tmp ad, accrualsdet t  
			 WHERE ad.trx_ctrl_num = t.trx_ctrl_num  AND t.to_post_flag=1  AND t.trans_type = 4  AND t.posted_flag IS NULL
			 AND t.accrual_number = @accrual_number
			 GROUP BY ad.trx_ctrl_num ) dt ON t.trx_ctrl_num = dt.trx_ctrl_num,		
			 (SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 4 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 where t.trx_ctrl_num = dt1.trx_ctrl_num 
			 AND t.posted_flag IS NULL

			drop table #apvocdt_tmp


			 /*UPDATE accrualsdet 
			 SET total_amt = dt.sumcol + dt1.sumtax 
			 FROM accrualsdet t JOIN 
			 (SELECT  ad.receipt_no,isnull(sum(ad.unit_cost * ad.quantity ),0) as sumcol 
			 FROM receipts ad, accrualsdet t  
			 WHERE ad.receipt_no = t.trx_ctrl_num  AND t.to_post_flag=1  AND t.trans_type = 4  AND ad.status = 'R' AND t.posted_flag IS NULL
			 AND t.accrual_number =@accrual_number
			 GROUP BY ad.receipt_no ) dt ON t.trx_ctrl_num = dt.receipt_no,		
			 (SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 4 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 where t.trx_ctrl_num = dt1.trx_ctrl_num 
			 AND t.posted_flag IS NULL*/

			--select * from accrualsdet where accrual_number = 'ACCR0000009'

			

		
			DROP TABLE #tmpinptaxdtl
			DROP TABLE #tmpinptax
			DROP TABLE #receipts_tmp	
		
		end



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apaccrualsupdaterec_sp] TO [public]
GO
