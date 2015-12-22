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

-- exec [cc_comments_aging_s_sp] '044944'

CREATE PROCEDURE [dbo].[cc_comments_aging_s_sp] 
	@customer_code varchar(20)
	
AS

	SELECT c.comment_id,
	user_name,
	CONVERT(varchar(30), comment_date,101) comment_date,
	comments,
	short_desc,
	(	SELECT followup_date 
		FROM cc_followups 
		WHERE customer_code = LTRIM(RTRIM(@customer_code))
		AND comment_id = c.comment_id) followup_date,
	(	SELECT comment_id 
		FROM cc_followups 
		WHERE customer_code = LTRIM(RTRIM(@customer_code))) comment_idx,
		priority 
	FROM 	cc_comments c LEFT OUTER JOIN cc_log_types l ON (c.log_type = l.log_type)
		LEFT OUTER JOIN cc_followups f ON (c.comment_id = f.comment_id)
	WHERE 	c.customer_code = LTRIM(RTRIM(@customer_code))
	AND ISNULL(DATALENGTH(RTRIM(LTRIM(doc_ctrl_num))), 0 ) = 0

	AND ( from_alerts <> 1 OR from_alerts IS NULL )

	ORDER BY c.comment_id DESC, row_num ASC

GO
GRANT EXECUTE ON  [dbo].[cc_comments_aging_s_sp] TO [public]
GO
