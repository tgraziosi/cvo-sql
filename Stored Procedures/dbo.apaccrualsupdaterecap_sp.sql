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

create procedure [dbo].[apaccrualsupdaterecap_sp]  
	@accrual_number varchar(16)
	as
		begin
		CREATE TABLE #APReceipts_tmp (
		tmp_ctrl_num  varchar(16),
		organization_id varchar(30))

	INSERT INTO #APReceipts_tmp(tmp_ctrl_num, organization_id) 
	SELECT distinct trx_ctrl_num, org_id FROM accrualsdet t
			WHERE t.accrual_number = @accrual_number
			AND t.to_post_flag=1
			AND t.trans_type =2
	
 

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
	

	 
			exec apaccrualsAPReceiptstax_sp
			

			

			 UPDATE accrualsdet 
			 SET total_amt = dt.sumcol + dt1.sumtax 
			 FROM accrualsdet t JOIN 
			 (SELECT  ad.receipt_ctrl_num,isnull(sum(ad.unit_price * (ad.qty_received - ad.qty_invoiced)),0) as sumcol 
			 FROM epinvdtl ad,epinvhdr ah, accrualsdet t  
			 WHERE ad.receipt_ctrl_num = t.trx_ctrl_num  AND t.to_post_flag=1  AND t.trans_type = 2   
			 AND ad.receipt_ctrl_num = ah.receipt_ctrl_num  
			 AND t.posted_flag IS NULL
			 AND t.accrual_number =@accrual_number
			 GROUP BY ad.receipt_ctrl_num  ) dt ON t.trx_ctrl_num = dt.receipt_ctrl_num,		
			 (SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 2 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 where t.trx_ctrl_num = dt1.trx_ctrl_num 
			 AND t.posted_flag IS NULL


		 


			--select * from accrualsdet where accrual_number = 'ACCR0000009'

			

		
			DROP TABLE #tmpinptaxdtl
			DROP TABLE #tmpinptax
			DROP TABLE #APReceipts_tmp 	
		
		end

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apaccrualsupdaterecap_sp] TO [public]
GO
