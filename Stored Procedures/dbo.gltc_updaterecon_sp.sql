SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*                                                        
               Confidential Information                    
    Limited Distribution of Authorized Persons Only         
    Created 2006 and Protected as Unpublished Work         
          Under the U.S. Copyright Act of 1976              
 Copyright (c) 2006 Epicor Software Corporation, 2006      
                  All Rights Reserved                      
*/                                                  
  
CREATE PROCEDURE [dbo].[gltc_updaterecon_sp]  
 @trx_ctrl_num varchar(16),   
 @trx_type smallint,   
 @doc_ctrl_num varchar(16),  
 @app_id  int,   
 @posted_flag smallint,   
 @remote_doc_id bigint,   
 @remote_state smallint,   
 @reconciled_flag smallint,   
 @amt_gross float,   
 @amt_tax  float,   
 @remote_amt_gross float,   
 @remote_amt_tax  float,   
 @customervendor_code varchar(8),   
 @date_doc int,   
 @reconciliated_date int,   
 @debug_level  smallint = 0  
  
AS  
IF NOT EXISTS(SELECT 1 FROM gltcrecon WHERE  trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type)  
 INSERT INTO gltcrecon  
  (trx_ctrl_num, trx_type, doc_ctrl_num, app_id, posted_flag, remote_doc_id, remote_state, reconciled_flag,   
  amt_gross, amt_tax, remote_amt_gross, remote_amt_tax, customervendor_code, date_doc, reconciliated_date)  
 VALUES (@trx_ctrl_num, @trx_type, @doc_ctrl_num, @app_id, @posted_flag, @remote_doc_id, @remote_state, @reconciled_flag,   
  @amt_gross, @amt_tax, @remote_amt_gross, @remote_amt_tax, @customervendor_code, @date_doc, @reconciliated_date)  
ELSE  
 UPDATE gltcrecon   
 SET  
  app_id = @app_id, posted_flag = @posted_flag, remote_doc_id = @remote_doc_id, remote_state = @remote_state,   
  reconciled_flag = @reconciled_flag, amt_gross = @amt_gross, amt_tax = @amt_tax, remote_amt_gross = @remote_amt_gross,   
  remote_amt_tax = @remote_amt_tax, customervendor_code = @customervendor_code,   
  date_doc = @date_doc, reconciliated_date = @reconciliated_date  
  , doc_ctrl_num = @doc_ctrl_num  
 WHERE trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type  
  
/**/                                                
GO
GRANT EXECUTE ON  [dbo].[gltc_updaterecon_sp] TO [public]
GO
