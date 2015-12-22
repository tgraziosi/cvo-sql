SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glpsupd_group2_sp] (@process_group_num VARCHAR(16), @company_code VARCHAR(8))
AS
DECLARE @doc_batch_mask varchar(16),
		@doc_batch_num varchar(16),
		@doc_batch varchar(16),
		@error_flag	smallint
DECLARE @batch_ctrl_num_group VARCHAR(16),
		@key_table VARCHAR(30)

CREATE TABLE #Group_batch_DIFF(
		key_table int IDENTITY(1,1),
		batch_ctrl_num_group char(16)) 

INSERT INTO #Group_batch_DIFF (batch_ctrl_num_group)
SELECT DISTINCT period_end_date
FROM batchctl BAT 
	INNER JOIN glprd PRD ON BAT.date_applied BETWEEN PRD.period_start_date AND PRD.period_end_date 
WHERE BAT.process_group_num = @process_group_num
	AND BAT.posted_flag <> 1 
	AND BAT.hold_flag = 0 

	
SET @key_table = 0

SELECT  @key_table = MIN(key_table)
FROM    #Group_batch_DIFF
WHERE   key_table > @key_table

WHILE @key_table IS NOT NULL
BEGIN

	SET @doc_batch_mask = (SELECT batch_group_ctrl_num_mask FROM glnumber)
	SET @doc_batch_num = (SELECT next_batch_group_ctrl_num FROM glnumber)

	EXEC fmtctlnm_sp @doc_batch_num, @doc_batch_mask, @doc_batch OUTPUT, @error_flag OUTPUT

	SET @batch_ctrl_num_group = (SELECT batch_ctrl_num_group FROM #Group_batch_DIFF WHERE key_table = @key_table)

    INSERT INTO #Group_batch
	SELECT @doc_batch, BAT.process_group_num, BAT.batch_ctrl_num, @company_code
	FROM batchctl BAT 
		INNER JOIN glprd PRD ON BAT.date_applied BETWEEN PRD.period_start_date AND PRD.period_end_date 
	WHERE BAT.process_group_num = @process_group_num AND PRD.period_end_date = @batch_ctrl_num_group
		AND BAT.posted_flag <> 1 
		AND BAT.hold_flag = 0 

	UPDATE glnumber 
		SET next_batch_group_ctrl_num = next_batch_group_ctrl_num + 1
	
    SELECT  @key_table = MIN(key_table)
    FROM    #Group_batch_DIFF
    WHERE   key_table > @key_table

END





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glpsupd_group2_sp] TO [public]
GO
