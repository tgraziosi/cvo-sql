SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
CREATE PROCEDURE [dbo].[APPOUnlockTransactions_SP] @batch_posting int,  @post_lock int,  @batch_post_lock int 
AS  IF @batch_posting = 1  UPDATE batchctl  SET posted_flag = 0  WHERE posted_flag = @batch_post_lock 
 UPDATE epmchhdr  SET match_posted_flag = 0  FROM epmchhdr  WHERE match_posted_flag = @post_lock 
RETURN 

 /**/
GO
GRANT EXECUTE ON  [dbo].[APPOUnlockTransactions_SP] TO [public]
GO
