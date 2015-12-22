SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlBuildSegDesc]
AS	         
BEGIN

	INSERT	frl_seg_desc(
				seg_code, entity_num, seg_num, 
				seg_code_desc, seg_short_desc)
	SELECT	seg_code, 1, 1, description, substring(short_desc, 1, 15)
	FROM		glseg1
	UNION
	SELECT	seg_code, 1, 2, description, substring(short_desc, 1, 15)
	FROM		glseg2
	UNION
	SELECT	seg_code, 1, 3, description, substring(short_desc, 1, 15)
	FROM		glseg3
	UNION
	SELECT	seg_code, 1, 4, description, substring(short_desc, 1, 15)
	FROM		glseg4

END
GO
GRANT EXECUTE ON  [dbo].[frlBuildSegDesc] TO [public]
GO
