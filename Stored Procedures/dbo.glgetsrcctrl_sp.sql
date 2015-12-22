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
CREATE PROCEDURE [dbo].[glgetsrcctrl_sp]  @src_ctrl_num varchar(16) OUTPUT AS BEGIN  DECLARE @company_id int, @found int 
 SELECT @src_ctrl_num = ''  SELECT @company_id = company_id from glco          BEGIN TRANSACTION getnum 
 SELECT @found = 1  WHILE (@found = 1)  BEGIN  SELECT @src_ctrl_num = next_src_ctrl_num from gl_glnumber where 
 company_id = @company_id  select @src_ctrl_num = isnull(@src_ctrl_num,'')  IF (@src_ctrl_num = '') 
 BEGIN  SELECT @src_ctrl_num = 1  INSERT into gl_glnumber (company_id, next_src_ctrl_num) 
 VALUES(@company_id, @src_ctrl_num)  END  UPDATE gl_glnumber set next_src_ctrl_num = next_src_ctrl_num+1 where 
 company_id = @company_id  IF NOT EXISTS (SELECT * from gl_glinphdr where src_ctrl_num = @src_ctrl_num ) SELECT @found = 0 
 END  COMMIT TRANSACTION getnum END 
GO
GRANT EXECUTE ON  [dbo].[glgetsrcctrl_sp] TO [public]
GO
