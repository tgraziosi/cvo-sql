SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\icv_fs_post_cradj_wrap.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[icv_fs_post_cradj_wrap] @user varchar(30), @process_ctrl_num varchar(16) AS 
BEGIN
DECLARE @err int
EXEC icv_fs_post_cradj @user, @process_ctrl_num, @err OUT
SELECT @err
END
GO
GRANT EXECUTE ON  [dbo].[icv_fs_post_cradj_wrap] TO [public]
GO
