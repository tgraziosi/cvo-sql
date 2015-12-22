SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
 
  
CREATE PROCEDURE [dbo].[cc_pyt_det_sp] @doc_ctrl_num varchar(16) = NULL, @customer_code varchar(8) = NULL  
AS  
  
  
-- v1.0 CB 06/06/2013 - Issue #1287 - Include voided checks in the detail  
-- v1.1 CB 26/06/2013 - Issue #1328 - Payment details missing when buying group payment applied to child accounts
-- v1.2 CB 01/07/2013 - Issue #1328 - When running by child include payments from parent
-- v1.3 CB 24/07/2013 - Issue #927 - Buying Group Switching
-- v1.4 CB 17/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
-- v1.5 CB 01/10/2013 - Issue #927 - Buying Group Switching - Deal with non BG customers
-- v1.6 CB 06/11/2013 - Fix issue with non BG parents
-- v1.7 CB 06/11/2013 - Peformance
-- v1.8 CB 09/12/2013 - Issue when customer is added and removed from buying group
-- v2.0 CB 10/06/2014 - ReWrite of BG data
-- v2.1 CB 15/09/2015 - #1524 - Add order number to payment history
  
DECLARE @pc varchar(8), @bal float, @cur varchar(8), @date int, @inv varchar(16), @org_net float 
DECLARE @relation_code varchar(10), -- v1.1 
		@IsParent int, -- v1.4
		@IsBG int -- v1.6
  
CREATE TABLE #pmt  
( doc_ctrl_num varchar(16),
 trx_type int null,  -- v1.0
 apply_to_num varchar(16),  
 date_doc int NULL,  
 price_code varchar(8) NULL,  
 amount float,  
 original_net float NULL,  
 balance float NULL,  
 apply_trx_type int,  
 nat_cur_code varchar(8) NULL,
  customer_code varchar(10),  -- v1.3 
  order_ctrl_num varchar(15)) -- v2.1
  
-- v1.1 Start
CREATE TABLE #cust (
	customer_code	varchar(8))

INSERT	#cust (customer_code)
SELECT	@customer_code

SELECT  @relation_code = credit_check_rel_code    
FROM	arco (NOLOCK)    


	IF OBJECT_ID('tempdb..#bg_data') IS NOT NULL
		DROP TABLE #bg_data

	CREATE TABLE #bg_data (
		doc_ctrl_num	varchar(16),
		order_ctrl_num	varchar(16),
		customer_code	varchar(10),
		doc_date_int	int,
		doc_date		varchar(10),
		parent			varchar(10))

	-- Call BG Data Proc
	EXEC cvo_bg_get_document_data_sp @customer_code
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)
	-- v1.5 Start    
	INSERT #cust    
	SELECT DISTINCT customer_code FROM #bg_data    
    


 INSERT #pmt( doc_ctrl_num, 
		 trx_type, -- v1.0
         apply_to_num,  
        amount,  
        apply_trx_type, customer_code, order_ctrl_num)  -- v1.3 v2.1
 SELECT  @doc_ctrl_num,  
	 trx_type, -- v1.0
     apply_to_num,   
     amount,   
     apply_trx_type, customer_code, -- v1.3  
		order_ctrl_num -- v2.1
 FROM artrxage  (NOLOCK)
 WHERE doc_ctrl_num = @doc_ctrl_num  
 AND  trx_type > 2031  
 AND ref_id > 0  
 AND doc_ctrl_num <> apply_to_num  
 AND customer_code IN (SELECT customer_code FROM #cust) -- v1.1  @customer_code  

 

 SELECT @inv = MIN ( apply_to_num ) FROM #pmt  
 WHILE ( @inv IS NOT NULL )  
  BEGIN  
   SELECT @pc = price_code,  
       @cur = nat_cur_code,  
      @bal = amt_net - amt_paid_to_date,  
      @org_net = amt_net,  
      @date = date_doc  
   FROM artrx (NOLOCK)  
   WHERE doc_ctrl_num = @inv  
    
   UPDATE #pmt  
   SET price_code = @pc,  
     balance = @bal,  
     original_net = @org_net,  
     nat_cur_code = @cur,  
     date_doc = @date  
   WHERE doc_ctrl_num = @doc_ctrl_num  
   AND apply_to_num = @inv  
  
   SELECT @inv = MIN ( apply_to_num ) FROM #pmt WHERE apply_to_num > @inv  
  END  
  

  -- v1.0 Start
 UPDATE #pmt  
 SET  apply_to_num = 'VOID ICR',  
    trx_type = 9999  
 WHERE trx_type = 2112  
  
 UPDATE #pmt  
 SET  apply_to_num = 'VOID CR',  
    trx_type = 9999  
 WHERE trx_type = 2113  
  
 UPDATE #pmt  
 SET  apply_to_num = 'NSF',  
    trx_type = 9999  
 WHERE trx_type = 2121  
  
 UPDATE #pmt  
 SET  apply_to_num = 'VOID WR',  
    trx_type = 9999  
 WHERE trx_type = 2142  
-- v1.0 End

 SELECT apply_to_num,  
    date_doc,  
    price_code,  
    amount,  
    balance,  
    apply_trx_type,  
    nat_cur_code,  
    original_net,
	order_ctrl_num -- v2.1  
 FROM #pmt  
 ORDER BY apply_to_num  

DROP TABLE #bg_data

GO
GRANT EXECUTE ON  [dbo].[cc_pyt_det_sp] TO [public]
GO
