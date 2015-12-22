SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_add_pop_kit_sp]	@soft_alloc_no	int,
												@order_no		int,
												@order_ext		int,
												@location		varchar(8),
												@part_no		varchar(30)
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id			int,
			@last_id	int,
			@kit_part	varchar(30),
			@qty		decimal(20,8)

	-- Create Working Table
	CREATE TABLE #pops (	id			int identity(1,1),
							part_no		varchar(30),
							qty			decimal(20,8))

	-- Execute the routine to return the promo items
	INSERT	#pops (part_no, qty)
	SELECT	a.part_no,   
	        a.qty
    FROM	what_part a (NOLOCK)  
	JOIN	inv_master b (NOLOCK) 
	ON		a.part_no = b.part_no
	WHERE	a.asm_no = @part_no

	IF EXISTS (SELECT 1 FROM #pops) -- pop parts exist
	BEGIN

		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@kit_part = part_no,
				@qty = qty
		FROM	#pops
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- Call the routine to add the promo items to the soft allocation
			EXEC dbo.cvo_add_soft_alloc_line_sp	@soft_alloc_no, @order_no, @order_ext, -2, @location, @kit_part, @qty, 0, 0, 0, 0, '', ''		

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@kit_part = part_no,
					@qty = qty
			FROM	#pops
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END

	DROP TABLE #pops

END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_add_pop_kit_sp] TO [public]
GO
