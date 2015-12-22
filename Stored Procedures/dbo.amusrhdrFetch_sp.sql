SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrhdrFetch_sp]
(
 @rowsrequested smallint = 1,
 @company_id smCompanyID,
 @user_field_id 		smUserFieldID,
		@user_field_subid				int
) as
 
 
SELECT 	timestamp, company_id, user_field_id, user_field_subid, user_field_type, user_field_title, user_field_length, validation_proc, zoom_id, min_value, max_value, selection, allow_null, default_value, updated_by
FROM 	amusrhdr
WHERE	company_id 		= @company_id
AND		user_field_id 	= @user_field_id
AND		user_field_subid= @user_field_subid
 
return @@error
GO
GRANT EXECUTE ON  [dbo].[amusrhdrFetch_sp] TO [public]
GO
