SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[fs_get_gl_accnt_descriptions]  @account1 varchar (32) , 
		@account2 varchar (32) , @account3 varchar (32) ,
		@account4 varchar (32) , @desc_1 varchar (40) out , 
		@desc_2 varchar (40) out , @desc_3 varchar (40) out ,
		@desc_4 varchar (40) out 
as
















select @desc_1 = account_description	 		-- mls 3/24/05 
  FROM adm_glchart_all (nolock)
  WHERE account_code = @account1

select @desc_2 = account_description	 		-- mls 3/24/05 
  FROM adm_glchart_all (nolock)
  WHERE account_code = @account2

select @desc_3 = account_description	 		-- mls 3/24/05 
  FROM adm_glchart_all (nolock)
  WHERE account_code = @account3

select @desc_4 = account_description	 		-- mls 3/24/05 
  FROM adm_glchart_all (nolock)
  WHERE account_code = @account4

return 0


GO
GRANT EXECUTE ON  [dbo].[fs_get_gl_accnt_descriptions] TO [public]
GO
