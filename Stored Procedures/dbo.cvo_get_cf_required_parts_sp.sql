SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_get_cf_required_parts_sp 'ASPKIT1'

CREATE PROC [dbo].[cvo_get_cf_required_parts_sp] @part_no varchar(30)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- WORKING TABLE
	CREATE TABLE #cf_required_parts (
		part_no		varchar(30),
		part_type	varchar(15),
		type_desc	varchar(100),
		qty			decimal(20,8))

	-- PROCESSING
	INSERT	#cf_required_parts
	SELECT	@part_no, category_code, description, 0
	FROM	category_3 (NOLOCK)
	WHERE	cf_process = 'Y'
	AND		void = 'N'
	ORDER BY category_code

	UPDATE	a
	SET		qty = b.qty
	FROM	#cf_required_parts a
	JOIN	cvo_cf_required_parts b (NOLOCK)
	ON		a.part_no = b.part_no
	AND		a.part_type = b.part_type

	-- RETURN
	SELECT	part_no,
			part_type,
			type_desc,
			qty
	FROM	#cf_required_parts
	ORDER BY part_type

END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_cf_required_parts_sp] TO [public]
GO
