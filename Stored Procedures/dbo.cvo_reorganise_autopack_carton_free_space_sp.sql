SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			cvo_reorganise_autopack_carton_free_space_sp		
Project ID:		Issue 690
Type:			Stored Proc
Description:	Moves stock into space freed up in cartons
Developer:		Chris Tyler

History
-------
v1.0	25/07/12	CT	Original version
v1.1	16/08/12	CT	Don't split lines across cartons

*/

CREATE PROC [dbo].[cvo_reorganise_autopack_carton_free_space_sp] (@carton_id INT)
AS
BEGIN

	DECLARE @order_no					INT,
			@order_ext					INT,
			@qty						DECIMAL(20,8),
			@qty_to_apply				DECIMAL(20,8),
			@free_space					DECIMAL(20,8),
			@max_carton					INT,
			@autopack_id				INT,
			@frame_link					INT,
			@case_link					INT,
			@case_link_deleted_line_no	INT,
			@new_case_link				INT

	SET @max_carton = 0

	-- How much space is available in carton
	SET @free_space  = dbo.f_return_autopack_carton_free_space(@carton_id)

	IF ISNULL(@free_space,0) = 0
	BEGIN
		RETURN 0
	END

	-- Get carton info
	SELECT TOP 1
		@order_no = order_no,
		@order_ext = order_ext
	FROM
		dbo.CVO_autopack_carton (NOLOCK)
	WHERE
		carton_id = @carton_id
	ORDER BY 
		autopack_id

	-- Get highest carton to move stock from
	SELECT 	@max_carton = MAX(carton_id) + 1 FROM dbo.CVO_autopack_carton (NOLOCK) 
	WHILE 1=1
	BEGIN
		
		SELECT  TOP 1
			@max_carton = carton_id
		FROM
			dbo.CVO_autopack_carton (NOLOCK)
		WHERE
			order_no = @order_no
			AND order_ext = @order_ext
			AND picked = 0
			AND carton_id < @max_carton
			AND carton_id <> @carton_id
		ORDER BY
			carton_id DESC

		IF @@ROWCOUNT = 0
			BREAK
	
		-- Move stock to original carton
		SET @autopack_id = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@autopack_id = autopack_id,
				@qty = qty,
				@case_link = case_link,
				@case_link_deleted_line_no = case_link_deleted_line_no
			FROM
				dbo.CVO_autopack_carton (NOLOCK)
			WHERE
				carton_id = @max_carton
				AND picked = 0
				AND part_type <> 'CASE'
				AND autopack_id > @autopack_id
				AND qty <= @free_space	-- v1.1
			ORDER BY
				autopack_id

			IF @@ROWCOUNT = 0
				BREAK


			IF @qty >= @free_space
			BEGIN
				SET @qty_to_apply = @free_space
				SET @free_space = 0
			END
			ELSE
			BEGIN
				SET @qty_to_apply = @qty
				SET @free_space = @free_space - @qty
			END	

			-- Create a new line for the stock
			INSERT INTO dbo.CVO_autopack_carton(
				carton_id,
				order_no,
				order_ext,
				line_no,
				part_no,
				part_type,
				case_link,
				case_link_deleted_line_no,
				frame_link,
				frame_link_deleted_line_no,
				qty,
				picked)
			SELECT
				@carton_id,
				order_no,
				order_ext,
				line_no,
				part_no,
				part_type,
				case_link,
				case_link_deleted_line_no,
				frame_link,
				frame_link_deleted_line_no,
				@qty_to_apply,
				0
			FROM
				dbo.CVO_autopack_carton (NOLOCK)
			WHERE
				autopack_id = @autopack_id

			SET @frame_link = @@IDENTITY

			-- Update original line
			UPDATE
				dbo.CVO_autopack_carton
			SET
				qty = qty - @qty_to_apply
			WHERE
				autopack_id = @autopack_id

			-- If the original line is now for zero delete it
			IF EXISTS (SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE	autopack_id = @autopack_id AND qty = 0)
			BEGIN
				DELETE FROM dbo.CVO_autopack_carton WHERE autopack_id = @autopack_id AND qty = 0
			END


			-- If there's a case line then move the same number of cases
			IF (ISNULL(@case_link,0) <> 0) AND (ISNULL(@case_link_deleted_line_no,0) = 0)
			BEGIN
				INSERT INTO dbo.CVO_autopack_carton(
					carton_id,
					order_no,
					order_ext,
					line_no,
					part_no,
					part_type,
					case_link,
					case_link_deleted_line_no,
					frame_link,
					frame_link_deleted_line_no,
					qty,
					picked)
				SELECT
					@carton_id,
					order_no,
					order_ext,
					line_no,
					part_no,
					part_type,
					case_link,
					case_link_deleted_line_no,
					@frame_link,
					NULL,
					CASE WHEN @qty_to_apply > qty THEN qty ELSE @qty_to_apply END,
					0
				FROM
					dbo.CVO_autopack_carton (NOLOCK)
				WHERE
					autopack_id = @case_link

				SET @new_case_link = @@IDENTITY

				-- Update original case line
				UPDATE
					dbo.CVO_autopack_carton
				SET
					qty = qty - CASE WHEN @qty_to_apply > qty THEN qty ELSE @qty_to_apply END
				WHERE
					autopack_id = @case_link

				-- If the original case line is now for zero delete it
				IF EXISTS (SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE	autopack_id = @case_link AND qty = 0)
				BEGIN
					DELETE FROM dbo.CVO_autopack_carton WHERE autopack_id = @case_link AND qty = 0
				END

				-- Update frame record with case_link
				UPDATE
					dbo.CVO_autopack_carton
				SET
					case_link = @new_case_link
				WHERE
					autopack_id = @frame_link
			END
		
			-- If the carton is now full return
			IF @free_space = 0
				BREAK
		END
		IF @free_space = 0
			BREAK
	END
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[cvo_reorganise_autopack_carton_free_space_sp] TO [public]
GO
