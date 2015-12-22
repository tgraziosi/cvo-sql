SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[cvo_ins_cashrec_sp]  
  
@trx_ctrl_num varchar(16),  
@customer_code varchar(8),  
@stmt_date  int  
  
AS  
  
IF EXISTS (SELECT 1 FROM cvo_cashrec_stmt_date WHERE trx_ctrl_num=@trx_ctrl_num AND customer_code=@customer_code)  
BEGIN  
 UPDATE cvo_cashrec_stmt_date  
 SET stmt_date = @stmt_date  
 WHERE customer_code = @customer_code  
END  
ELSE  
BEGIN  
 INSERT INTO cvo_cashrec_stmt_date (trx_ctrl_num,customer_code,stmt_date)  
 VALUES(@trx_ctrl_num,@customer_code,@stmt_date)  
  
END  

GO
GRANT EXECUTE ON  [dbo].[cvo_ins_cashrec_sp] TO [public]
GO
