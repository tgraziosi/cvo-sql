SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                

                                               
 
CREATE PROCEDURE [dbo].[appost_accruals]
	@accrual_number varchar(16),
	@process_ctrl_num varchar(16),
	@debug int
	

	AS
	BEGIN
	 	DECLARE 
			@debug_level int,
			@result    int,
			@str_msg_at		VARCHAR(255),
			@org_company varchar(8),
			@smuser_id int

	
		SELECT @org_company=(SELECT company_code FROM glcomp_vw (nolock) WHERE company_id=(SELECT company_id FROM glco(nolock)))
		
		--EXEC appgetstring_sp 'STR_ACCRUAL_POSTING', @str_msg_at  OUT
		SELECT @smuser_id = user_id FROM accrualshdr (nolock) where accrual_number = @accrual_number
		
		

		
			
		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'apinpchg')
		BEGIN
			exec @result = apgentrxGLVO_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id, @debug
			if @result != 0
			BEGIN
			 select @result 	
			 RETURN @result 
			END
		END
		
		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'adm_pomchchg_all')
		BEGIN
			exec @result = apgentrxGLMatchADM_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id,@debug
			if @result != 0
			BEGIN
			 select @result
			 RETURN @result 
			END
		END
		
		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'releases')
		BEGIN
 			exec @result = apgentrxGLRecADM_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id,@debug
			if @result != 0
			BEGIN
			 select @result 	
			 RETURN @result 
			END
		END
		
		
		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'adm_vend_all')
		BEGIN
			exec @result = apgentrxGLPurADM_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id,@debug
			if @result != 0
			BEGIN
			 select @result	
			 RETURN @result 
			END
		END
		
		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'epmchhdr')
		BEGIN
			exec @result = apgentrxGLMatchAPMatch_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id,@debug
			if @result != 0
			BEGIN
			 select @result
			 RETURN @result 
			END
		END

		IF  EXISTS (SELECT 1 FROM sysobjects WHERE name = 'epinvhdr')
		BEGIN
			exec @result = apgentrxGLReceipAPMatch_sp @accrual_number, @process_ctrl_num, @org_company, @smuser_id,@debug
			if @result != 0
			BEGIN
				 select @result
			 RETURN @result 
			END
		END
		
		select @result 'result'
	END

	
	IF EXISTS(select 1 from glco (nolock) where indirect_flag = 0 )
	BEGIN
		UPDATE	gltrx SET	posted_flag = -1   
		WHERE gltrx.posted_flag = 0 AND gltrx.hold_flag = 0 AND type_flag IN ( 0, 2, 3, 4, 5 ) 
		AND process_group_num = @process_ctrl_num
		AND trx_type != 121 
	END
	
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appost_accruals] TO [public]
GO
