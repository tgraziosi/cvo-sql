SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arrecov.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 










































































































































































































































































 

































































































CREATE PROCEDURE [dbo].[arrecov_sp]	@process_group_num varchar(16), 
				@batch_code varchar(16),
				@debug smallint
				
				
AS

BEGIN
	DECLARE @batch_proc_flag smallint


	 
	SELECT @batch_proc_flag = batch_proc_flag FROM arco
	
	IF ( ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ) )
		SELECT @batch_code = '%'

	
	IF (@batch_proc_flag = 0)
		UPDATE	arinpchg
		SET	posted_flag = 0,
			batch_code = ''
		WHERE	process_group_num = @process_group_num
		AND	batch_code like @batch_code
	ELSE
		UPDATE	arinpchg
		SET	posted_flag = 0
		WHERE	process_group_num = @process_group_num
		AND	batch_code like @batch_code

	
	UPDATE	arinpchg
	SET	printed_flag = 0
	FROM	pcontrol_vw
	WHERE	pcontrol_vw.process_ctrl_num = @process_group_num
	AND	arinpchg.process_group_num = pcontrol_vw.process_ctrl_num
	AND	pcontrol_vw.process_type = 2899

	
	IF (@batch_proc_flag = 0)
		UPDATE	arinppyt
		SET	posted_flag = 0,
			batch_code = ''
		WHERE	process_group_num = @process_group_num
		AND	batch_code like @batch_code
		
	ELSE
		UPDATE	arinppyt
		SET	posted_flag = 0
		WHERE	process_group_num = @process_group_num
		AND	batch_code like @batch_code
	
	
	UPDATE	artrx
	SET	posted_flag = 1
	WHERE	process_group_num = @process_group_num

	
	IF (@batch_proc_flag = 0)
		UPDATE batchctl
		SET	void_flag = 1,
			process_group_num = '',
		 	posted_flag = 0
		WHERE	process_group_num = @process_group_num
		AND	batch_ctrl_num like @batch_code
		AND	batch_type BETWEEN 2000 AND 3000
	ELSE
		UPDATE	batchctl
		SET	posted_flag = 0,
			process_group_num = ''
		WHERE	process_group_num = @process_group_num
		AND	batch_ctrl_num like @batch_code
		AND	batch_type BETWEEN 2000 AND 3000


	RETURN 0
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arrecov_sp] TO [public]
GO
