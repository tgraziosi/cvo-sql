SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[fs_post_ap_wrap] @user varchar(30), @process_group_num varchar(16),     
@type int=4091 , @online_call int = 1 AS    
BEGIN    
    
DECLARE @err1 int     
  
exec @err1 = fs_post_ap @user, @process_group_num, @type, @err1 OUT, @online_call    
  
return @err1  
    
END    
GO
GRANT EXECUTE ON  [dbo].[fs_post_ap_wrap] TO [public]
GO
