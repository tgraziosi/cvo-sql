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


CREATE PROCEDURE [dbo].[cc_comments_is_sp]	
		@doc_ctrl_num varchar(20),
		@customer_code	varchar(8)
	
AS

SELECT 	comment_id,
	user_name,
	comment_date,
	comments,
	NULL,
	NULL,
	NULL,
	NULL
	FROM cc_comments c LEFT OUTER JOIN cc_log_types l ON (c.log_type = l.log_type)
	WHERE doc_ctrl_num = @doc_ctrl_num
	AND customer_code = @customer_code	
	ORDER BY comment_id DESC, row_num ASC

GO
GRANT EXECUTE ON  [dbo].[cc_comments_is_sp] TO [public]
GO
