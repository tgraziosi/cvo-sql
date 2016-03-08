
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 08/05/2015 - #1085 - Show distribution customer logs in C&C and visa versa  
-- v1.1 CB 01/03/2016 - Use the timestamp as a comment id to ensure the notes are split
CREATE PROCEDURE [dbo].[cc_comments_s_sp] @customer_code varchar(20)   
AS 
BEGIN 
  
	SELECT	c.comment_id,  
			user_name,  
			CONVERT(varchar(30), comment_date,101) note_date,  
			comments,  
			short_desc,  
			(SELECT followup_date   
				FROM	cc_followups   
				WHERE	customer_code = LTRIM(RTRIM(@customer_code))  
				AND		comment_id = c.comment_id),  
			(SELECT comment_id   
				FROM	cc_followups   
				WHERE	customer_code = LTRIM(RTRIM(@customer_code))),  
			priority,
			comment_date order_date   
	FROM	cc_comments c 
	LEFT OUTER JOIN cc_log_types l 
	ON		(c.log_type = l.log_type)  
	LEFT OUTER JOIN cc_followups f 
	ON		(c.comment_id = f.comment_id)  
	WHERE	c.customer_code = LTRIM(RTRIM(@customer_code))  
	AND		ISNULL(DATALENGTH(RTRIM(LTRIM(doc_ctrl_num))), 0 ) = 0    
	AND		( from_alerts <> 1 OR from_alerts IS NULL )  
--	ORDER BY c.comment_id DESC, row_num ASC 
	UNION 
--	SELECT	-1 comment_id, -- v1.1
	SELECT	CAST(timestamp as int) comment_id, -- v1.1
			who_entered user_name,
			CONVERT(varchar(30), date_entered,101) note_date, 	
			note comment,
			'DIST' short_desc,
			NULL, NULL, NULL,
			date_entered order_date
	FROM	dbo.cust_log (NOLOCK)
	WHERE	customer_key = LTRIM(RTRIM(@customer_code))
	ORDER BY order_date DESC		
END
GO

GRANT EXECUTE ON  [dbo].[cc_comments_s_sp] TO [public]
GO
