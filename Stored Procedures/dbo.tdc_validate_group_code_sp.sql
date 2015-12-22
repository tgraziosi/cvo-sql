SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_validate_group_code_sp]
	@strGroup_Code		VARCHAR (10) ,
	@strGroup_Code_ID	VARCHAR(20)
AS


IF (SELECT COUNT(*)  FROM tdc_bin_group (NOLOCK)
 	 WHERE group_code = @strGroup_Code
 	AND    group_code_id =@strGroup_Code_ID) = 0
 BEGIN

	SELECT TOP 1 group_code_id
  		FROM tdc_bin_group (NOLOCK)
  		WHERE group_code = @strGroup_Code
 END

ELSE
	BEGIN
		SELECT  @strGroup_Code_ID AS group_code_id
	END
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_group_code_sp] TO [public]
GO
