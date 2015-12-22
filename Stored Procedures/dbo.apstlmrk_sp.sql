SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
                                                                                 
   CREATE PROCEDURE [dbo].[apstlmrk_sp]  @process_ctrl_num varchar(16),  @debug smallint = 0 
AS DECLARE @total smallint,  @valid smallint,  @settlement_ctrl_num varchar(16), 
 @hold_flag smallint BEGIN IF (@debug > 0) SELECT "Entering apstlmrk_sp" SELECT DISTINCT 
 settlement_ctrl_num INTO #settlements FROM apinppyt WHERE process_group_num = @process_ctrl_num 
WHILE 1=1 BEGIN  SELECT @settlement_ctrl_num = NULL,  @total = 0,  @valid = 0  SELECT @settlement_ctrl_num = MIN( settlement_ctrl_num) 
 FROM #settlements  IF ( @settlement_ctrl_num IS NULL )  break  SELECT @hold_flag = hold_flag 
 FROM apinpstl  WHERE settlement_ctrl_num = @settlement_ctrl_num      IF (@hold_flag=1) 
 BEGIN  UPDATE apinppyt  SET process_group_num = "",  posted_flag = 0  WHERE settlement_ctrl_num = @settlement_ctrl_num 
 END  ELSE  BEGIN      SELECT @total = COUNT(*)  FROM apinppyt  WHERE settlement_ctrl_num = @settlement_ctrl_num 
     SELECT @valid = COUNT(*)  FROM apinppyt  WHERE process_group_num = @process_ctrl_num 
             IF (@total <= @valid)      BEGIN  UPDATE apinpstl  SET process_group_num = @process_ctrl_num, 
 state_flag = -1  WHERE settlement_ctrl_num = @settlement_ctrl_num  IF (@debug > 0) 
 SELECT "Mark settlement "+@settlement_ctrl_num+ "for posting."  END  ELSE       BEGIN 
 UPDATE apinppyt  SET process_group_num = "",  posted_flag = 0  WHERE settlement_ctrl_num = @settlement_ctrl_num 
 IF (@debug > 0)  SELECT "Unmark settlement "+@settlement_ctrl_num+ "for posting." 
 END  END  DELETE #settlements  WHERE settlement_ctrl_num = @settlement_ctrl_num 
END DROP TABLE #settlements IF (@debug > 0)  SELECT "Exiting apstlmrk_sp" RETURN 0 
END 
GO
GRANT EXECUTE ON  [dbo].[apstlmrk_sp] TO [public]
GO
