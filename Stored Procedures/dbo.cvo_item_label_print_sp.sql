SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_item_label_print_sp]	@part_no_1 varchar(30),
										@upc_code_1 varchar(30),
										@label_qty_1 int,
										@part_no_2 varchar(30),
										@upc_code_2 varchar(30),
										@label_qty_2 int,
										@part_no_3 varchar(30),
										@upc_code_3 varchar(30),
										@label_qty_3 int										
AS
BEGIN
	-- tag - 051518 - add F1 to BT frames when needed

	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @label_count	int

	-- WORKING TABLES
	CREATE TABLE #cvo_label_print (
		row_id			int IDENTITY(1,1),
		part_no			varchar(30),
		part_desc		varchar(255),
		type_code		varchar(10),
		is_revo			smallint,
		upc_code		varchar(20),
		category		varchar(20),
		cvo				varchar(30),
		frame_model		varchar(40),
		frame_color		varchar(40),
		frame_size		varchar(40),
		bridge			varchar(40),
		temple			varchar(40),
		lens_color		varchar(20),
		res_type		varchar(15),
		print_model		varchar(100),
		print_color		varchar(100),
		print_size		varchar(255))
		
	-- PROCESSING
	IF (ISNULL(@part_no_1,'') > '')
	BEGIN
		SET @label_count = @label_qty_1

		WHILE (@label_count > 0)
		BEGIN
			INSERT	#cvo_label_print (part_no, part_desc, type_code, is_revo, upc_code, category, cvo, frame_model, frame_color, frame_size, 
					bridge, temple, lens_color, res_type, print_model, print_color, print_size)
			SELECT	@part_no_1, a.description, a.type_code, 
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN 1 ELSE 0 END,
					@upc_code_1, 
					a.category,
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN @part_no_1 ELSE 'CLEARVISION' END,
					ISNULL(b.field_2,'') + CASE WHEN a.category = 'BT' AND RIGHT(a.part_no,2) = 'F1' THEN ' F1' ELSE '' END frame_model,
					ISNULL(b.field_3,''),
					CASE WHEN b.field_17 IS NULL THEN '' WHEN b.field_17 = 0 THEN '' ELSE CAST(CAST(b.field_17 as int) as varchar(40)) END,
					ISNULL(b.field_6,''),
					ISNULL(b.field_8,''),
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN ISNULL(b.field_23,'') ELSE '' END,					
					ISNULL(b.category_3,''),
					'', '', ''					
			FROM	inv_master a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.part_no = @part_no_1
					AND A.VOID = 'N'

			SET @label_count = @label_count - 1
		END
	END

	IF (ISNULL(@part_no_2,'') > '')
	BEGIN
		SET @label_count = @label_qty_2

		WHILE (@label_count > 0)
		BEGIN
			INSERT	#cvo_label_print (part_no, part_desc, type_code, is_revo, upc_code, category, cvo, frame_model, frame_color, frame_size, 
					bridge, temple, lens_color, res_type, print_model, print_color, print_size)
			SELECT	@part_no_2, a.description, a.type_code, 
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN 1 ELSE 0 END,
					@upc_code_2, 
					a.category,
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN @part_no_2 ELSE 'CLEARVISION' END,
					ISNULL(b.field_2,'') + CASE WHEN a.category = 'BT' AND RIGHT(a.part_no,2) = 'F1' THEN ' F1' ELSE '' END frame_model,
					ISNULL(b.field_3,''),
					CASE WHEN b.field_17 IS NULL THEN '' WHEN b.field_17 = 0 THEN '' ELSE CAST(CAST(b.field_17 as int) as varchar(40)) END,
					ISNULL(b.field_6,''),
					ISNULL(b.field_8,''),
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN ISNULL(b.field_23,'') ELSE '' END,					
					ISNULL(b.category_3,''),
					'', '', ''					
			FROM	inv_master a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.part_no = @part_no_2
					AND A.VOID = 'N'

			SET @label_count = @label_count - 1
		END
	END

	IF (ISNULL(@part_no_3,'') > '')
	BEGIN
		SET @label_count = @label_qty_3

		WHILE (@label_count > 0)
		BEGIN
			INSERT	#cvo_label_print (part_no, part_desc, type_code, is_revo, upc_code, category, cvo, frame_model, frame_color, frame_size, 
					bridge, temple, lens_color, res_type, print_model, print_color, print_size)
			SELECT	@part_no_3, a.description, a.type_code, 
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN 1 ELSE 0 END,
					@upc_code_3, 
					a.category,
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN @part_no_3 ELSE 'CLEARVISION' END,
					ISNULL(b.field_2,'') + CASE WHEN a.category = 'BT' AND RIGHT(a.part_no,2) = 'F1' THEN ' F1' ELSE '' END frame_model,
					ISNULL(b.field_3,''),
					CASE WHEN b.field_17 IS NULL THEN '' WHEN b.field_17 = 0 THEN '' ELSE CAST(CAST(b.field_17 as int) as varchar(40)) END,
					ISNULL(b.field_6,''),
					ISNULL(b.field_8,''),
					CASE WHEN a.type_code = 'SUN' AND LEFT(a.category,4) = 'REVO' THEN ISNULL(b.field_23,'') ELSE '' END,					
					ISNULL(b.category_3,''),
					'', '', ''					
			FROM	inv_master a (NOLOCK)
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	a.part_no = @part_no_3
					AND VOID = 'N'

			SET @label_count = @label_count - 1
		END
	END

	UPDATE	#cvo_label_print
	SET		print_model = category + ' ' + frame_model
	WHERE	type_code IN ('SUN','FRAME')
	AND		(frame_size = '' OR bridge = '' OR temple = '') 

	UPDATE	#cvo_label_print
	SET		print_model = category + ' ' + frame_model,
			print_size = CASE WHEN is_revo = 0 THEN frame_size + '/' + bridge + '/' + temple ELSE lens_color END
	WHERE	type_code IN ('SUN','FRAME')
	AND		NOT (frame_size = '' AND bridge = '' AND temple = '') 


	UPDATE	#cvo_label_print
	SET		print_model = frame_model,
			print_size = UPPER(type_code)
	WHERE	type_code = 'PATTERN'

	UPDATE	#cvo_label_print
	SET		print_model = category + ' ' + frame_model,
			print_size = CASE WHEN LEFT(UPPER(res_type),6) = 'TEMPLE' THEN res_type + ' (' + temple + ')'
							  WHEN LEFT(UPPER(res_type),7) = 'DEMOLEN' THEN res_type + ' (' + frame_size + ')'
							  ELSE UPPER(res_type) END			
	WHERE	type_code = 'PARTS'

	UPDATE	#cvo_label_print
	SET		print_model = frame_model,
			print_size = part_desc
	WHERE	type_code NOT IN ('SUN','FRAME','PATTERN','PARTS')

	UPDATE	#cvo_label_print
	SET		print_color = frame_color

	SELECT	@label_count = COUNT(1)
	FROM	#cvo_label_print

	IF (@label_count <= 3)
		SET @label_count = 3 - @label_count
	ELSE
	BEGIN
		IF ((@label_count % 3) <> 0)
			SET @label_count = 3 - (@label_count % 3)
		ELSE
			SET @label_count = 0
	END

	WHILE (@label_count > 0)
	BEGIN
		INSERT	#cvo_label_print (part_no, part_desc, type_code, is_revo, upc_code, cvo, frame_model, frame_color, frame_size, 
					bridge, temple, lens_color, res_type, print_model, print_color, print_size)
		SELECT	'','','',0,'','','','','','','','','','','',''	

		SET @label_count = @label_count - 1
	END 

	SELECT	part_no, part_desc, upc_code, cvo, print_model, print_color, print_size
	FROM	#cvo_label_print
	ORDER BY row_id
	
END



GO
GRANT EXECUTE ON  [dbo].[cvo_item_label_print_sp] TO [public]
GO
