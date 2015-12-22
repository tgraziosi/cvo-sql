SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                         CREATE PROC [dbo].[gl_cleaninp_sp]  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16) AS BEGIN     IF EXISTS (SELECT * FROM gl_glinphdr  WHERE src_trx_id = @src_trx_id 
 AND src_ctrl_num = @src_ctrl_num  AND src_doc_num LIKE '####-%'  AND post_flag = 0) 
 BEGIN  BEGIN TRANSACTION     DELETE FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END  DELETE FROM gl_glinpdet WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END  COMMIT TRANSACTION 
 END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_cleaninp_sp] TO [public]
GO
