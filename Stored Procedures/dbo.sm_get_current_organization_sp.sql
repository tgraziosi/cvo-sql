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






























CREATE PROC [dbo].[sm_get_current_organization_sp]
		@name 		sysname,
		@org_id 	varchar(30) = '' OUTPUT,
		@org_name 	varchar(60) = '' OUTPUT,
		@status		int	    = 0  OUTPUT,
		@debug_flag 	int
AS
	declare @ib_flag int
	SELECT @status 	= 0, @org_id  = ''

	select @ib_flag = ib_flag 
	from glco

	if @ib_flag = 0
	BEGIN
		
		select 	@org_id = organization_id,
			@org_name = organization_name
		from 	Organization_all
		where outline_num ='1'
	

		
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @status 	= -100
			RETURN
		END

		IF @debug_flag > 0  select org_id = @org_id, organization_name = @org_name

	END
	ELSE
	BEGIN
		
		
		SELECT 	@org_id = org_id,
			@org_name = organization_name
		FROM  	sm_current_organization
		WHERE 	name = @name

		
		IF @@ROWCOUNT = 0
		BEGIN		
				
				SELECT @org_id 	 = '', @org_name = '', @status 	 = -200
				RETURN
		END
	
		IF @org_id in ('', NULL)
		BEGIN
				
				SELECT @org_id 	 = '', @org_name = '', @status = -300
				RETURN
		END

		IF @debug_flag > 0  select org_id = @org_id, organization_name = @org_name
	END

RETURN 0
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[sm_get_current_organization_sp] TO [public]
GO
