SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			cvo_remove_order_from_autopack_carton_sp		
Project ID:		Issue 690
Type:			Stored Proc
Description:	Removes stock from an autopack carton
Developer:		Chris Tyler

History
-------
v1.0	25/07/12	CT	Original version
v1.1	24/09/12	CB	modify to work with soft allocation
v1.2	03/10/12	CT	Reorganize carton code moved to this routine (from CVO_assign_to_autopack_carton_sp)

*/

CREATE PROC [dbo].[cvo_remove_order_from_autopack_carton_sp] (@order_no INT, @order_ext INT)
AS
BEGIN

	DECLARE	@rec_key	INT,
			@line_no	INT,
			@part_no	VARCHAR(30),
			@qty		DECIMAL (20,8),
			@max_carton_id	INT,	-- v1.2
			@carton_id		INT		-- v1.2


	CREATE TABLE #deleted (
		rec_key		INT IDENTITY (1,1),
		order_no	INT,
		order_ext	INT,
		line_no		INT,
		part_no		VARCHAR(30),
		qty			DECIMAL (20,8))

	INSERT INTO #deleted(
		order_no,
		order_ext,
		line_no,
		part_no,
		qty)
	SELECT
		s.order_no,
		s.order_ext,
		s.line_no,
		s.part_no,
		s.qty
	FROM
		tdc_soft_alloc_tbl s
	INNER JOIN
		dbo.orders_all o (NOLOCK)
	ON
		s.order_no = o.order_no
		AND s.order_ext = o.ext
	WHERE
		s.order_no = @order_no
		AND s.order_ext = @order_ext
		AND s.order_type = 'S'
		AND o.[type] = 'I' 
		AND LEFT(o.user_category,2) = 'ST' 
		AND s.location < '100'
	ORDER BY
		s.order_no,
		s.order_ext,
		s.line_no

	-- v1.1 Start
	IF (OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL) 
		DROP TABLE #cvo_ord_list

	CREATE TABLE #cvo_ord_list(
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		add_case varchar(1) NULL DEFAULT ('N'),
		add_pattern varchar(1) NULL DEFAULT ('N'),
		from_line_no int NULL,
		is_case int NULL DEFAULT ((0)),
		is_pattern int NULL DEFAULT ((0)),
		add_polarized varchar(1) NULL DEFAULT ('N'),
		is_polarized int NULL DEFAULT ((0)),
		is_pop_gif int NULL DEFAULT ((0)))
	EXEC dbo.CVO_create_fc_relationship_sp @order_no, @order_ext
	-- v1.1 End

	-- Loop through table
	SET @rec_key = 0

	WHILE 1=1 
	BEGIN

		SELECT TOP 1
			@rec_key = rec_key,
			@line_no = line_no,
			@part_no = part_no,
			@qty = (qty * -1)
		FROM
			#deleted
		WHERE
			rec_key > @rec_key
		ORDER BY
			rec_key

		IF @@ROWCOUNT = 0
			BREAK

		-- Call autopack carton routine
		EXEC CVO_assign_to_autopack_carton_sp @order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @part_no = @part_no, @qty = @qty	
	END
	
	-- START v1.2
	-- If there are any cartons for this order that are now not full then reorganise
	SET @carton_id = 0
	SELECT @max_carton_id = MAX(carton_id) FROM dbo.CVO_autopack_carton (NOLOCK) WHERE order_no = @order_no	AND order_ext = @order_ext

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@carton_id = carton_id
		FROM
			dbo.CVO_autopack_carton (NOLOCK)
		WHERE
			order_no = @order_no
			AND order_ext = @order_ext
			AND dbo.f_return_autopack_carton_free_space(carton_id) > 0
			AND carton_id <> @max_carton_id
			AND carton_id > @carton_id
		ORDER BY 
			carton_id

		IF @@ROWCOUNT = 0
			BREAK

		EXEC cvo_reorganise_autopack_carton_free_space_sp @carton_id

	END
	-- END v1.2

	DROP TABLE #deleted	

END

GO
GRANT EXECUTE ON  [dbo].[cvo_remove_order_from_autopack_carton_sp] TO [public]
GO
