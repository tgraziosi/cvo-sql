SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE  PROCEDURE [dbo].[sm_exist_trx_sp] 
@name_table varchar(255), 
 @trx_ctrl_num_to_find varchar(16), 
 @col1_find varchar(80),
 @col2_find varchar(100)
AS
BEGIN		
   
   DECLARE @SQLString nvarchar(255)

   SET @SQLString = (dbo.sm_access_exist_trx_fn(@name_table ,@trx_ctrl_num_to_find,@col1_find,@col2_find ))
   
   exec sp_executesql @SQLString
   
END
GO
GRANT EXECUTE ON  [dbo].[sm_exist_trx_sp] TO [public]
GO
