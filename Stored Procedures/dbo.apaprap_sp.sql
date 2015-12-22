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




























































































CREATE PROCEDURE	[dbo].[apaprap_sp]

	@user_id smallint,	@sys_date int,  @form_type smallint
AS



DECLARE	@trx_num 	varchar(32),	@trx_type 	smallint,	
	@appr_code 	varchar(16),	@err_flag 	smallint,	
	@err_mess 	varchar(80),	@approved_flag 	smallint,
	@sequence_flag 	smallint, 	@appr_seq_id  	smallint,
	@disappr_flag	smallint,	@disappr_id	smallint




WHILE ( 1 = 1 )
BEGIN
	SET	ROWCOUNT  1
	SELECT	@trx_num = NULL

	


	IF	@form_type = 1
	BEGIN
	   SELECT @trx_num = trx_ctrl_num,
		  @trx_type = trx_type,
		  @appr_code = approval_code,
		  @approved_flag = approved_flag,
		  @disappr_flag = disappr_flag,
		  @sequence_flag = sequence_flag,
		  @appr_seq_id  = appr_seq_id
	   FROM	  apaprtrx
	   WHERE  user_id = @user_id
	   AND	  changed_flag = 1
	END
	ELSE
	BEGIN
	   SELECT @trx_num = trx_ctrl_num,
		  @trx_type = trx_type,
		  @appr_code = approval_code,
		  @approved_flag = approved_flag,
		  @disappr_flag = disappr_flag,
		  @sequence_flag = sequence_flag,
		  @appr_seq_id  = appr_seq_id
	   FROM	  apaprtrx
	   WHERE  disappr_user_id = @user_id
	   AND	  changed_flag = 1
	END

	SET	ROWCOUNT  0

	


	IF ( @trx_num IS NULL )
	BEGIN
		SELECT	0, " "
		RETURN
	END

	


	IF	@form_type = 1
	BEGIN
		UPDATE	apaprtrx
		SET	changed_flag = 0
		WHERE	user_id = @user_id
		AND	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @appr_code
	END
	ELSE
	BEGIN
		UPDATE	apaprtrx
		SET	changed_flag = 0
		WHERE	disappr_user_id = @user_id
		AND	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @appr_code
	END

	


	IF ( @approved_flag = 1 )
	BEGIN
	   



	   IF	@form_type = 2
		UPDATE	apaprtrx
		SET	disable_flag = 0
	   	WHERE	trx_ctrl_num = @trx_num
	   	AND	trx_type = @trx_type
	   	AND	approval_code = @appr_code
		
	   



	   IF NOT EXISTS( SELECT trx_ctrl_num FROM apaprtrx
	   		WHERE	trx_ctrl_num = @trx_num
	      		AND	trx_type = @trx_type
		   	AND   	approved_flag = 0 )
	   BEGIN
	   	UPDATE	apaprtrx
	   	SET	appr_complete = 1,
			display_flag = 0
	   	WHERE	trx_ctrl_num = @trx_num
	   	AND	trx_type = @trx_type

	   	



	   	IF NOT EXISTS( SELECT 	trx_ctrl_num FROM apaprtrx
	   			WHERE 	trx_ctrl_num = @trx_num
				AND	trx_type = @trx_type
			   	AND   	approved_flag = 0 )
		BEGIN
		   



		   IF @trx_type = 4091	
			UPDATE	apinpchg
			SET	approval_flag = 0
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
		   ELSE IF @trx_type = 4111
			UPDATE	apinppyt
			SET	approval_flag = 0
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
				else if @trx_type = 4090
				begin
					update purchase_all
					set approval_flag = 0
					where po_no = @trx_num
				end


	   			
		   

	
		   IF (  @@ROWCOUNT = 0 )
		   BEGIN
		   	SELECT	@err_mess = STR(@trx_type, 4)
		   		+ " & " + RTRIM( @trx_num )
				+ " is invalid in APINPCHG!"
			SELECT	1, @err_mess
			RETURN
		   END
		END
	   END
	   ELSE
	   BEGIN
		



		UPDATE	apaprtrx
		SET   	display_flag = 1
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @appr_code
		AND     appr_seq_id = @appr_seq_id + 1
		AND	@sequence_flag = 1
	   END

	END
	ELSE 	
	BEGIN
	   




	   IF @disappr_flag = 1 AND @form_type = 1
	   BEGIN
		


		SELECT	@disappr_id = disappr_user_id
		FROM	apapr
		WHERE	approval_code = @appr_code

	   	UPDATE	apaprtrx
	   	SET	disable_flag = 1,
			disappr_user_id = @disappr_id
	      	WHERE	trx_ctrl_num = @trx_num
	      	AND	trx_type = @trx_type
	   	AND	approval_code = @appr_code
	   END

	   




	   ELSE IF @disappr_flag = 0 AND @form_type = 2
	   	UPDATE	apaprtrx
	   	SET	disable_flag = 0
	      	WHERE	trx_ctrl_num = @trx_num
	      	AND	trx_type = @trx_type
	   	AND	approval_code = @appr_code
	END
END			









GO
GRANT EXECUTE ON  [dbo].[apaprap_sp] TO [public]
GO
