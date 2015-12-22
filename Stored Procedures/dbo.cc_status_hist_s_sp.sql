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

CREATE PROCEDURE [dbo].[cc_status_hist_s_sp]	@doc_ctrl_num varchar(16)

AS


	DECLARE @user_name varchar(30),
					@cleared_by	varchar(30),
					@last_row	int

	CREATE TABLE #stat_hist
	(	doc_ctrl_num	varchar(16) NULL,
		status_code		varchar(5) NULL,
		status_desc		varchar(65) NULL,
		[date]				int NULL,
		[user_id]			smallint NULL,
		[user_name]		varchar(30) NULL,
		clear_date		int NULL,
		cleared_by		smallint NULL,
		cleared_name	varchar(30) NULL,
		sequence_num	smallint NULL
	)

	INSERT #stat_hist 
	(	doc_ctrl_num,
		status_code,
		status_desc,
		[date],
		[user_id],
		clear_date,
		cleared_by,
		sequence_num
	)
	SELECT 	doc_ctrl_num,
					h.status_code,
					status_desc,
					[date],
					[user_id],
					clear_date,
					cleared_by,
					sequence_num
	FROM cc_inv_status_hist h LEFT OUTER JOIN cc_status_codes c ON (h.status_code = c.status_code)
	WHERE doc_ctrl_num = @doc_ctrl_num
	ORDER BY sequence_num DESC


	SELECT @last_row = MIN(sequence_num) FROM #stat_hist
	WHILE @last_row IS NOT NULL
		BEGIN
			SELECT @user_name = s.[user_name] 
			FROM CVO_Control..smusers s, #stat_hist h
			WHERE	s.[user_id] = h.[user_id]
			AND	sequence_num = @last_row
		
			SELECT @cleared_by = s.[user_name] 
			FROM CVO_Control..smusers s, #stat_hist h
			WHERE	s.[user_id] = h.cleared_by
			AND	sequence_num = @last_row

			UPDATE #stat_hist 
			SET [user_name] = CASE WHEN [user_id] = 1 THEN 'sa' ELSE @user_name END, 
					cleared_name = CASE WHEN cleared_by = 1 THEN 'sa' ELSE @cleared_by END
			WHERE sequence_num = @last_row

			SELECT @user_name = '', @cleared_by = ''

			SELECT @last_row = MIN(sequence_num) 
			FROM #stat_hist
			WHERE sequence_num > @last_row
		END

	SELECT	status_code,
					date, 
					status_desc, 
					[user_name],
					clear_date, 
					cleared_name,
					sequence_num
	FROM #stat_hist
	ORDER BY sequence_num DESC

GO
GRANT EXECUTE ON  [dbo].[cc_status_hist_s_sp] TO [public]
GO
