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
                                           CREATE PROC [dbo].[gl_deletedet_sp]  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16),  @src_line_id int,  @return_code int OUTPUT AS BEGIN 
    SELECT @return_code = 0  SELECT @src_ctrl_num = LTRIM(RTRIM(@src_ctrl_num))  IF @src_trx_id IS NULL OR @src_ctrl_num IS NULL OR @src_line_id IS NULL 
 BEGIN  SELECT @return_code = 8101  RETURN @return_code  END  IF @src_trx_id = '' OR @src_ctrl_num = '' OR @src_line_id <= 0 
 BEGIN  SELECT @return_code = 8101  RETURN @return_code  END  BEGIN TRANSACTION   
  DELETE FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  SELECT @return_code = 8100  RETURN @return_code 
 END     UPDATE gl_glinpdet  SET src_line_id = src_line_id - 1  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id > @src_line_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  SELECT @return_code = 8100  RETURN @return_code 
 END  COMMIT TRANSACTION  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_deletedet_sp] TO [public]
GO
