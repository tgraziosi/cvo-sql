SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 21/08/2012 - Looks for case/pattern lines on an order which are linked to frame lines which no longer exist, if found, the link is broken

CREATE PROC [dbo].[cvo_break_orhpaned_relationships_sp] (@order_no INT, @order_ext INT)
AS
BEGIN
	DECLARE @line_no INT,
			@from_line_no INT

	SET @line_no = 0
	WHILE 1=1
	BEGIN
		-- Loop through lines which are linked to other lines
		SELECT TOP 1
			@line_no = line_no,
			@from_line_no = from_line_no
		FROM
			dbo.cvo_ord_list (NOLOCK)
		WHERE
			order_no = @order_no
			AND order_ext = @order_ext
			AND line_no > @line_no
			AND ISNULL(from_line_no,0) <> 0
		ORDER BY
			line_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Does the from_line exist on this order
		IF NOT EXISTS (SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @from_line_no)
		BEGIN
			-- Remove reference
			UPDATE
				dbo.cvo_ord_list
			SET
				from_line_no = 0
			WHERE
				order_no = @order_no 
				AND order_ext = @order_ext 
				AND line_no = @line_no
		END 
	END

END

GO
GRANT EXECUTE ON  [dbo].[cvo_break_orhpaned_relationships_sp] TO [public]
GO
