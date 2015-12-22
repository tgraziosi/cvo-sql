SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_check_events_sp]	@contract_ctrl_num	varchar(16),
																		@member_type	smallint = 0,	/* 	0 = contract level
																																		1 = customer
																																		2 = price class
																																		3 = vendor
																																		4 = vendor class
																																		5 = part
																																		6 = category
																																		*/
																		@member_code	varchar(32) = ''
																		
AS

	IF @member_type = 0
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"')
	IF @member_type = 1					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	customer_code = "' + @member_code + '"')

	IF @member_type = 2					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	price_class = "' + @member_code + '"')

	IF @member_type = 3					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	vendor_code = "' + @member_code + '"')

	IF @member_type = 4					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	vendor_class = "' + @member_code + '"')

	IF @member_type = 5					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	part_no = "' + @member_code + '"')

	IF @member_type = 6					
		EXEC ('	SELECT COUNT(*) 
						FROM pr_events 
						WHERE contract_ctrl_num = "' + @contract_ctrl_num + '"
						AND	category = "' + @member_code + '"')

GO
GRANT EXECUTE ON  [dbo].[pr_check_events_sp] TO [public]
GO
