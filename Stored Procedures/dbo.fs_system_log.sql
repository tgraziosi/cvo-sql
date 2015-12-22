SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_system_log]
	(
	@message	VARCHAR(255),
	@type_flag	CHAR(1) = 'T',
	@source		CHAR(3) = NULL
	)

AS
BEGIN

INSERT INTO dbo.system_log(type_flag,source,message)
VALUES (@type_flag,@source,@message)

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_system_log] TO [public]
GO
