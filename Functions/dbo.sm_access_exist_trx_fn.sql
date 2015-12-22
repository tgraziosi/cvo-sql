SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE  FUNCTION [dbo].[sm_access_exist_trx_fn] 
(@name_table varchar(255), 
 @trx_ctrl_num_to_find varchar(16), 
 @where1_find varchar(80),
 @where2_find varchar(100))
RETURNS varchar(500) 
BEGIN		
   DECLARE @SQLString NVARCHAR(500),
           @Param1_name_table NVARCHAR(100),
           @Param2_where      NVARCHAR(100), 
           @Param3_where      NVARCHAR(100),
           @ret SMALLINT

  SET @Param1_name_table = (RTRIM(@name_table)+ '_all')   

  SET @Param2_where = ISNULL(RTRIM(@where1_find), ' ') +
         N' = '+ "'" + ISNULL(RTRIM(@trx_ctrl_num_to_find), ' ' ) + "'" 

  SET @Param3_where =  ISNULL(RTRIM(@where2_find),' ')
           

  IF ( LTRIM(RTRIM( @Param2_where)) = '=')
  BEGIN  
   SET @SQLString = 'SELECT -300'   
  END
  ELSE
   BEGIN
   
    SET @SQLString = N'IF EXISTS ( SELECT * FROM ' + @Param1_name_table + ' WHERE  '+ @Param2_where + ' '+ @Param3_where + ' ) SELECT 1 ELSE SELECT 0'
   
    --EXEC sp_executesql @SQLString, @Param1_name_table ,  @Param2_where 
 
   END	
   RETURN  @SQLString
END
GO
GRANT REFERENCES ON  [dbo].[sm_access_exist_trx_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_access_exist_trx_fn] TO [public]
GO
