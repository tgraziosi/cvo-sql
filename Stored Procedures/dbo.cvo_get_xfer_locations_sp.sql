SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_get_xfer_locations_sp 1670, '001'

CREATE PROC [dbo].[cvo_get_xfer_locations_sp] @xfer_no int, 
										  @location varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@part_no	varchar(30)

	-- WORKING TABLES
	CREATE TABLE #xfer_parts (
		part_no		varchar(30))

	CREATE TABLE #xfer_loc (
		location	varchar(10),
		qty			int)

	-- PROCESSING
	INSERT	#xfer_parts
	SELECT	DISTINCT part_no
	FROM	xfer_list (NOLOCK)
	WHERE	xfer_no = @xfer_no

	INSERT	#xfer_loc
	SELECT	location, 0
	FROM	locations_all (NOLOCK)
	WHERE	location <> @location

	SET @part_no = ''

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @part_no = part_no
		FROM	#xfer_parts
		WHERE	part_no > @part_no
		ORDER BY part_no ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		DELETE	#xfer_loc
		WHERE	location NOT IN (SELECT location FROM inv_list (NOLOCK) WHERE part_no = @part_no)

	END

	SELECT	location, qty
	FROM	#xfer_loc
	ORDER BY location

	DROP TABLE #xfer_parts
	DROP TABLE #xfer_loc

END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_xfer_locations_sp] TO [public]
GO
