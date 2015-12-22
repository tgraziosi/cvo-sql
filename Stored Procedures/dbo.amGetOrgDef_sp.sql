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

CREATE PROCEDURE [dbo].[amGetOrgDef_sp]
(
    @org_id  		varchar(30)      OUTPUT,
    @org_desc 		varchar(60)      OUTPUT
  
 )
AS
	declare  @ibflag  int
 	SELECT @ibflag = 0, @org_id ='',@org_desc =''
        SELECT @ibflag = ib_flag 
        FROM   glco
        
        IF @ibflag = 0 
	BEGIN
	   SELECT @org_id = organization_id,
	          @org_desc = organization_name 
	   FROM   Organization 
	   WHERE  outline_num ='1'
	END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amGetOrgDef_sp] TO [public]
GO
