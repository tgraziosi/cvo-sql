SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[tl_set_link_data] 
	@Data1 	varchar(30)='',
	@Data2  varchar(30)='',
	@FormID int

AS
	DECLARE @linktable_exists smallint
	
	SELECT @linktable_exists = 0
	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..##linktable') IS NULL) BEGIN
		SELECT @linktable_exists = 1
	END
	IF @linktable_exists = 0 BEGIN
		CREATE TABLE ##linktable
		(
		 Data1  varchar(30),
		 Data2  varchar(30),
		 FormID int,
		 user_id int
		)
	END
	
	DELETE ##linktable
		WHERE FormID = @FormID
		AND  user_id = USER_ID()
	
	INSERT INTO ##linktable
		VALUES (@Data1, @Data2, @FormID,  USER_ID())
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[tl_set_link_data] TO [public]
GO
