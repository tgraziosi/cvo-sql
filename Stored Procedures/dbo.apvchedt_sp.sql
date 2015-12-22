SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
  
  
CREATE PROCEDURE [dbo].[apvchedt_sp]  @only_errors smallint, @debug_level smallint = 0  
AS  
  
DECLARE  
         @result int, @error_level smallint  
  
  
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvchedt.cpp' + ', line ' + STR( 39, 5 ) + ' -- ENTRY: '  
  
IF ((SELECT COUNT(1) FROM #apvovchg) < 1) RETURN 0  
  
IF @only_errors = 1  
   SELECT @error_level = 0  
ELSE   
 SELECT @error_level = 1  
  
  
EXEC @result = apvehdr1_sp @error_level, @debug_level  
  
EXEC @result = apvehdr2_sp @error_level, @debug_level  
  
EXEC @result = apvehdr3_sp @error_level, @debug_level  
  
EXEC @result = apvehdr4_sp @error_level, @debug_level  
  
EXEC @result = apvehdr5_sp @error_level, @debug_level  
  
EXEC @result = apvehdr6_sp @error_level, @debug_level  
  
EXEC @result = apvedet1_sp @error_level, @debug_level  
  
EXEC @result = apvedet2_sp @error_level, @debug_level  
  
EXEC @result = apvesub1_sp @error_level, @debug_level  
  
EXEC @result = apvesub2_sp @error_level, @debug_level  
  
EXEC @result = apvesub3_sp @error_level, @debug_level  
  
  
  
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvchedt.cpp' + ', line ' + STR( 73, 5 ) + ' -- EXIT: '  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[apvchedt_sp] TO [public]
GO
