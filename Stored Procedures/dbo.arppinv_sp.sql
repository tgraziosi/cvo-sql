SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arppinv.SPv - e7.2.2 : 1.16
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 










































































































































































































































































 
















































































CREATE PROC [dbo].[arppinv_sp]	@trx_ctrl_num		varchar( 16 ), 
				@trx_type 		smallint, 
				@set_post_flag	smallint, 
				@retry_flag		smallint = NULL
AS

DECLARE	@doc_ctrl_num 	varchar( 16 ),	 
		@num			int, 
		@num_type		int

BEGIN 
	SELECT @doc_ctrl_num = doc_ctrl_num
	FROM 	arinpchg 
	WHERE 	trx_ctrl_num = @trx_ctrl_num	
	AND 	trx_type = @trx_type


	
	IF ( @doc_ctrl_num = SPACE(1) )
	BEGIN
		
		SELECT	@doc_ctrl_num = NULL

		WHILE ( @doc_ctrl_num IS NULL )
		BEGIN
			
			IF @trx_type = 2031
				SELECT @num_type = 2001
			ELSE IF @trx_type = 2032
				SELECT @num_type = 2021
				
			EXEC ARGetNextControl_SP	@num_type,
							@doc_ctrl_num OUTPUT,
							@num OUTPUT

			
			IF @doc_ctrl_num IS NULL
				RETURN


			
			IF EXISTS(	SELECT doc_ctrl_num 
					FROM artrx 
					WHERE doc_ctrl_num = @doc_ctrl_num
					AND trx_type = @trx_type)
			BEGIN
				IF ( @retry_flag = 1 )
					SELECT @doc_ctrl_num = NULL
				ELSE
				BEGIN
					ROLLBACK TRAN
					RETURN
				END
			END
			ELSE
			BEGIN
				IF EXISTS(	SELECT	doc_ctrl_num
						FROM	arinpchg
						WHERE	doc_ctrl_num = @doc_ctrl_num
						AND 	trx_type = @trx_type)
				BEGIN
					IF ( @retry_flag = 1 )
						SELECT @doc_ctrl_num = NULL
					ELSE
					BEGIN
						ROLLBACK TRAN
						RETURN
					END

				END
			END
		END

		
		UPDATE	arinpchg
		SET	doc_ctrl_num = @doc_ctrl_num,
			printed_flag = @set_post_flag
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = @trx_type
	END

END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arppinv_sp] TO [public]
GO
