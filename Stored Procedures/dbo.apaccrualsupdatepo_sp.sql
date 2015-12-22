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
create procedure [dbo].[apaccrualsupdatepo_sp]  
	@accrual_number varchar(16)
	as
		begin
			CREATE TABLE #purchaseorders_tmp (
			po_no varchar(16))
		
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
			amt_final_tax float NOT NULL)
		 
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
			account_code varchar(32) NOT NULL)
			
			INSERT INTO #purchaseorders_tmp(po_no) SELECT distinct trx_ctrl_num FROM accrualsdet t
			WHERE t.accrual_number = @accrual_number
			AND t.to_post_flag=1
			AND t.trans_type =6
		
			EXEC apaccrualspotax_sp
			
		

			 create table #apvocdt_tmp (
			 trx_ctrl_num varchar(30),
			 amt_extended float,
			 tax_code varchar(8),
			 calc_tax float	)

			 insert into #apvocdt_tmp
			 SELECT  ad.po_no as trx_ctrl_num,isnull(ad.unit_cost * (ad.qty_ordered - ad.qty_received),0) as amt_extended,ad.tax_code, 
			 isnull(ad.total_tax,0) as calc_tax 
			 FROM pur_list ad, accrualsdet t  
			 WHERE ad.po_no = t.trx_ctrl_num  
			 AND t.to_post_flag=1  
                         AND t.trans_type = 6  
                         AND t.posted_flag IS NULL
			 AND t.accrual_number = @accrual_number
			AND (ad.qty_ordered - ad.qty_received) > 0
		

			UPDATE d SET d.calc_tax = t.sum_tax
			FROM #apvocdt_tmp d 
				INNER JOIN (
					select trx_ctrl_num, tax_code, SUM(amt_final_tax) as sum_tax
					from #tmpinptaxdtl t inner join aptaxdet ty on (ty.tax_type_code = t.tax_type_code)
					group by trx_ctrl_num, tax_code) t
				ON (d.trx_ctrl_num  = t.trx_ctrl_num AND d.tax_code = t.tax_code)



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
			 WHERE ad.trx_ctrl_num = t.trx_ctrl_num  AND t.to_post_flag=1  AND t.trans_type = 6  AND t.posted_flag IS NULL
			 AND t.accrual_number = @accrual_number
			 GROUP BY ad.trx_ctrl_num ) dt ON t.trx_ctrl_num = dt.trx_ctrl_num,		
			 (SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 6 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 where t.trx_ctrl_num = dt1.trx_ctrl_num 
			 AND t.posted_flag IS NULL

			drop table #apvocdt_tmp

			/*
			 UPDATE accrualsdet 
			 SET total_amt = dt.sumcol + dt1.sumtax 
			 FROM accrualsdet t JOIN 
			 (SELECT  ad.po_no,isnull(sum(ad.unit_cost * (ad.qty_ordered - ad.qty_received)),0) as sumcol, isnull(sum(ad.total_tax),0) as sumtax 
			 FROM pur_list ad, accrualsdet t  
			 WHERE ad.po_no = t.trx_ctrl_num  AND t.to_post_flag=1  AND t.trans_type = 6  AND t.posted_flag IS NULL
			 AND t.accrual_number = @accrual_number
			 GROUP BY ad.po_no ) dt ON t.trx_ctrl_num = dt.po_no,		
			 (SELECT #tmpinptax.trx_ctrl_num,sum(#tmpinptax.amt_final_tax) as sumtax 
		         from #tmpinptax, accrualsdet chg 
		         where #tmpinptax.trx_ctrl_num = chg.trx_ctrl_num  
			 AND chg.accrual_number = @accrual_number
			 AND chg.to_post_flag = 1  AND chg.trans_type = 6 AND chg.posted_flag IS NULL
		         group by #tmpinptax.trx_ctrl_num) dt1 
			 where t.trx_ctrl_num = dt1.trx_ctrl_num 
			 AND t.posted_flag IS NULL
			*/

			

		
			DROP TABLE #tmpinptaxdtl
			DROP TABLE #tmpinptax
			DROP TABLE #purchaseorders_tmp	
		
		end

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apaccrualsupdatepo_sp] TO [public]
GO
